const bcrypt = require('bcryptjs'); // The password scrambler
const User = require('./models/User'); // Your new blueprint
require('dotenv').config(); // This loads your hidden .env file
const express = require('express');
const cors = require('cors');
const mongoose = require('mongoose'); // The MongoDB library

const app = express();
// This tells the app: "Use the port provided by Render, OR use 5000 if running locally"
const PORT = process.env.PORT || 5000;

app.use(cors({
    origin: '*', // This allows all websites (like your Flutter web build) to talk to your API
}));
app.use(express.json());

// --- MONGODB CONNECTION ---
mongoose.connect(process.env.MONGO_URI)
    .then(() => console.log("✅ Successfully connected to MongoDB Atlas!"))
    .catch((err) => console.error("❌ MongoDB connection error:", err));

// ... (Keep your existing /api/analyze and /api/recommend routes here) ...


// --- AUTHENTICATION ROUTES ---

// SIGN UP ROUTE
app.post('/api/signup', async (req, res) => {
    // 1. Grab the data sent from the frontend
    const { email, password, codeforcesHandle } = req.body;

    try {
        // 2. Check if this user already exists
        const existingUser = await User.findOne({ email: email });
        if (existingUser) {
            return res.status(400).json({ error: "An account with this email already exists." });
        }

        // 3. Hash (scramble) the password for security
        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash(password, salt);

        // 4. Create the new user object
        const newUser = new User({
            email: email,
            password: hashedPassword,
            codeforcesHandle: codeforcesHandle
        });

        // 5. Save it permanently to MongoDB Atlas
        await newUser.save();

        // 6. Tell the frontend it worked
        res.status(201).json({
            message: "User created successfully!",
            handle: codeforcesHandle
        });

    } catch (error) {
        console.error("Signup Error:", error);
        res.status(500).json({ error: "Internal Server Error" });
    }
});


// LOG IN ROUTE
app.post('/api/login', async (req, res) => {
    const { email, password } = req.body;

    try {
        // 1. See if a user with this email even exists
        const user = await User.findOne({ email: email });
        if (!user) {
            return res.status(400).json({ error: "Invalid email or password." });
        }

        // 2. Compare the typed password with the scrambled one in the database
        const isMatch = await bcrypt.compare(password, user.password);
        if (!isMatch) {
            return res.status(400).json({ error: "Invalid email or password." });
        }

        // 3. If it matches, success! Send back their handle.
        res.json({
            message: "Login successful!",
            handle: user.codeforcesHandle
        });

    } catch (error) {
        console.error("Login Error:", error);
        res.status(500).json({ error: "Internal Server Error" });
    }
});



app.listen(PORT, () => {
    console.log(`🚀 Server is running at http://localhost:${PORT}`);
});


app.get('/api/analyze/:handle', async (req, res) => {
    const handle = req.params.handle;
    const url = `https://codeforces.com/api/user.status?handle=${handle}`;

    try {
        console.log(`\nFetching data for: ${handle}...`);

        const response = await fetch(url);
        const data = await response.json();

        if (data.status !== 'OK') {
            return res.status(404).json({ error: "User not found or Codeforces API is down." });
        }

        const submissions = data.result;

        // Dictionary to store stats for each tag
        // Format: { "dp": { attempted: 10, solved: 4 }, "math": { attempted: 20, solved: 18 } }
        const tagStats = {};

        // Loop through all submissions to aggregate data
        for (let sub of submissions) {
            // We only care about submissions that actually have tags
            if (!sub.problem.tags || sub.problem.tags.length === 0) continue;

            const isSolved = sub.verdict === 'OK';

            for (let tag of sub.problem.tags) {
                // Initialize the tag in our dictionary if we haven't seen it yet
                if (!tagStats[tag]) {
                    tagStats[tag] = { attempted: 0, solved: 0 };
                }

                // We only count unique attempts per problem to avoid skewing data 
                // if someone submitted WA 10 times on the same problem.
                // For simplicity in this V1, we'll just count raw submissions.
                tagStats[tag].attempted++;
                if (isSolved) {
                    tagStats[tag].solved++;
                }
            }
        }

        // Transform the dictionary into an array and calculate the Win Rate %
        const analysisReport = Object.keys(tagStats).map(tag => {
            const stats = tagStats[tag];
            const winRate = ((stats.solved / stats.attempted) * 100).toFixed(2);

            return {
                topic: tag,
                attempted: stats.attempted,
                solved: stats.solved,
                winRate: parseFloat(winRate)
            };
        });

        // Sort topics by lowest win rate first (to find the biggest weaknesses!)
        analysisReport.sort((a, b) => a.winRate - b.winRate);

        res.json({
            handle: handle,
            totalSubmissions: submissions.length,
            weakestTopics: analysisReport.slice(0, 5), // Top 5 worst topics
            fullReport: analysisReport
        });

    } catch (error) {
        console.error("Error:", error);
        res.status(500).json({ error: "Internal Server Error" });
    }
});


// NEW ROUTE: The Recommendation Engine
app.get('/api/recommend/:handle', async (req, res) => {
    const handle = req.params.handle;

    try {
        console.log(`\nGenerating recommendations for ${handle}...`);

        // 1. Get user rating
        const infoUrl = `https://codeforces.com/api/user.info?handles=${handle}`;
        const infoResponse = await fetch(infoUrl);
        const infoData = await infoResponse.json();

        if (infoData.status !== 'OK') return res.status(404).json({ error: "User not found" });

        // Default to 1200 if they are unrated
        const userRating = infoData.result[0].rating || 1200;
        const targetRating = userRating + 100; // Push them slightly out of their comfort zone

        // 2. Get user submissions to find solved problems and weak topics
        const statusUrl = `https://codeforces.com/api/user.status?handle=${handle}`;
        const statusResponse = await fetch(statusUrl);
        const statusData = await statusResponse.json();

        const solvedProblemIds = new Set();
        const tagStats = {};

        for (let sub of statusData.result) {
            if (sub.verdict === 'OK') {
                // Create a unique ID for the problem (e.g., "1500A")
                solvedProblemIds.add(`${sub.problem.contestId}${sub.problem.index}`);
            }

            // Re-calculate weak topics
            if (sub.problem.tags) {
                for (let tag of sub.problem.tags) {
                    if (!tagStats[tag]) tagStats[tag] = { attempted: 0, solved: 0 };
                    tagStats[tag].attempted++;
                    if (sub.verdict === 'OK') tagStats[tag].solved++;
                }
            }
        }

        // Find the weakest topic with at least 5 attempts (to avoid skewed data on rare tags)
        let weakestTopic = "implementation"; // Fallback topic
        let lowestWinRate = 100;

        for (let tag in tagStats) {
            const stats = tagStats[tag];
            if (stats.attempted >= 5) {
                const winRate = (stats.solved / stats.attempted) * 100;
                if (winRate < lowestWinRate) {
                    lowestWinRate = winRate;
                    weakestTopic = tag;
                }
            }
        }

        // 3. Fetch the entire Codeforces problemset
        const problemsUrl = `https://codeforces.com/api/problemset.problems`;
        const problemsResponse = await fetch(problemsUrl);
        const problemsData = await problemsResponse.json();

        // 4. Filter the problems
        const recommendedProblems = [];

        for (let problem of problemsData.result.problems) {
            const problemId = `${problem.contestId}${problem.index}`;

            // Check if it matches our strict criteria:
            // 1. Has the weak tag
            // 2. Is appropriately rated (+100 to +300 of current rating)
            // 3. Has NOT been solved by the user yet
            if (
                problem.tags &&
                problem.tags.includes(weakestTopic) &&
                problem.rating >= targetRating &&
                problem.rating <= targetRating + 200 &&
                !solvedProblemIds.has(problemId)
            ) {
                recommendedProblems.push({
                    name: problem.name,
                    rating: problem.rating,
                    tags: problem.tags,
                    link: `https://codeforces.com/contest/${problem.contestId}/problem/${problem.index}`
                });
            }

            // Stop once we find 5 good recommendations
            if (recommendedProblems.length >= 5) break;
        }

        // 5. Send the final payload back to the client
        res.json({
            handle: handle,
            currentRating: userRating,
            targetRating: targetRating,
            weakestTopicIdentified: weakestTopic,
            recommendations: recommendedProblems
        });

    } catch (error) {
        console.error("Error:", error);
        res.status(500).json({ error: "Internal Server Error" });
    }
});



app.listen(PORT, () => {
    console.log(`Server is running at http://localhost:${PORT}`);
});