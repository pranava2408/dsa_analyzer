require('dotenv').config(); 
const express = require('express');
const cors = require('cors');
const mongoose = require('mongoose'); 
const bcrypt = require('bcryptjs'); 
const nodemailer = require('nodemailer');
const User = require('./models/User'); 

console.log("--- DIAGNOSTIC CHECK ---");
console.log("EMAIL:", process.env.EMAIL_USER);
console.log("PASS LENGTH:", process.env.EMAIL_PASS ? process.env.EMAIL_PASS.length : "UNDEFINED");
console.log("------------------------");

const transporter = nodemailer.createTransport({
    host: 'smtp.gmail.com',
    port: 465,
    secure: true, // Use SSL
    auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASS
    },
    // This forces the connection to resolve properly on strict networks like Render
    tls: {
        rejectUnauthorized: false
    }
})

const app = express();
const PORT = process.env.PORT || 5000;

app.use(cors({
    origin: '*',
    methods: ['GET', 'POST', 'DELETE', 'UPDATE', 'PUT', 'PATCH'],
    allowedHeaders: ['Content-Type', 'Authorization', 'Origin', 'Accept']
}));

app.use(express.json());

// --- MONGODB CONNECTION ---
mongoose.connect(process.env.MONGO_URI)
    .then(() => console.log("✅ Successfully connected to MongoDB Atlas!"))
    .catch((err) => console.error("❌ MongoDB connection error:", err));


// --- AUTHENTICATION ROUTES ---

// 1. SIGN UP ROUTE
app.post('/api/signup', async (req, res) => {
    const { email, password, codeforcesHandle } = req.body;

    try {
        let user = await User.findOne({ email: email });
        const otpCode = Math.floor(100000 + Math.random() * 900000).toString();
        const otpExpiresTime = new Date(Date.now() + 10 * 60 * 1000);

        if (user) {
            if (user.isVerified) {
                return res.status(400).json({ error: "An account with this email already exists." });
            }

            const salt = await bcrypt.genSalt(10);
            user.password = await bcrypt.hash(password, salt);
            user.codeforcesHandle = codeforcesHandle;
            user.otp = otpCode;
            user.otpExpires = otpExpiresTime;

            await user.save();
            console.log(`Updated OTP for unverified user: ${email}`);

        } else {
            const salt = await bcrypt.genSalt(10);
            const hashedPassword = await bcrypt.hash(password, salt);

            user = new User({
                email: email,
                password: hashedPassword,
                codeforcesHandle: codeforcesHandle,
                isVerified: false,
                otp: otpCode,
                otpExpires: otpExpiresTime
            });
            await user.save();
            console.log(`Created new unverified user: ${email}`);
        }

        try {
            const mailOptions = {
                from: process.env.EMAIL_USER,
                to: email,
                subject: 'DSA Helper - Your Verification Code',
                html: `
                  <div style="font-family: Arial, sans-serif; text-align: center; padding: 20px;">
                    <h2>Welcome to DSA Helper!</h2>
                    <p>Here is your new 6-digit verification code:</p>
                    <h1 style="color: #3B82F6; letter-spacing: 5px; background: #f3f4f6; padding: 10px; border-radius: 8px; display: inline-block;">
                      ${otpCode}
                    </h1>
                    <p>This code will expire in 10 minutes.</p>
                  </div>
                `
            };
            await transporter.sendMail(mailOptions);
            console.log(`OTP successfully sent via Gmail to ${email}`);
        } catch (emailError) {
            console.error("Gmail failed to send email:", emailError);
        }

        res.status(201).json({
            message: "Verification code sent! Please check your email.",
            requireOtp: true,
            email: email
        });

    } catch (error) {
        console.error("Signup Error:", error);
        res.status(500).json({ error: "Internal Server Error" });
    }
});

// 2. VERIFY OTP ROUTE
app.post('/api/verify-otp', async (req, res) => {
    const { email, otp } = req.body;

    try {
        const user = await User.findOne({ email: email });

        if (!user) return res.status(404).json({ error: "User not found." });
        if (user.isVerified) return res.status(400).json({ error: "Email is already verified. You can log in." });
        if (user.otp !== otp) return res.status(400).json({ error: "Invalid verification code. Please try again." });
        if (new Date() > user.otpExpires) return res.status(400).json({ error: "Code has expired. Please sign up again." });

        user.isVerified = true;
        user.otp = undefined;        
        user.otpExpires = undefined; 
        await user.save();

        res.status(200).json({
            message: "Email verified successfully!",
            handle: user.codeforcesHandle
        });

    } catch (error) {
        console.error("OTP Verification Error:", error);
        res.status(500).json({ error: "Internal Server Error" });
    }
});

// 3. LOG IN ROUTE
app.post('/api/login', async (req, res) => {
    const { email, password } = req.body;

    try {
        const user = await User.findOne({ email: email });
        if (!user) return res.status(400).json({ error: "Invalid email or password." });
        if (user.isVerified === false) return res.status(403).json({ error: "Please verify your email before logging in." });

        const isMatch = await bcrypt.compare(password, user.password);
        if (!isMatch) return res.status(400).json({ error: "Invalid email or password." });

        res.json({
            message: "Login successful!",
            handle: user.codeforcesHandle
        });

    } catch (error) {
        console.error("Login Error:", error);
        res.status(500).json({ error: "Internal Server Error" });
    }
});


// --- DATA ANALYSIS ROUTE ---

// 4. ANALYZE ROUTE (THE SINGLE, CORRECT VERSION)
app.get('/api/analyze/:handle', async (req, res) => {
    const handle = req.params.handle;
    const statusUrl = `https://codeforces.com/api/user.status?handle=${handle}`;
    const infoUrl = `https://codeforces.com/api/user.info?handles=${handle}`;

    try {
        console.log(`\nFetching full profile and data for: ${handle}...`);

        // --- 1. FETCH USER RATING ---
        const infoResponse = await fetch(infoUrl);
        const infoData = await infoResponse.json();

        if (infoData.status !== 'OK') {
            return res.status(404).json({ error: "User not found" });
        }

        const userRating = infoData.result[0].rating || 0;

        // --- 2. FETCH USER SUBMISSIONS ---
        const response = await fetch(statusUrl);
        const data = await response.json();

        if (data.status !== 'OK') {
            return res.status(404).json({ error: "Codeforces API is down." });
        }

        const submissions = data.result;

        // --- 3. TRACK UNIQUE DATA ---
        const tagStats = {};
        const globalSolvedProblems = new Set();
        const ratingDist = {};

        for (let sub of submissions) {
            if (!sub.problem.tags || sub.problem.tags.length === 0) continue;

            const problemId = `${sub.problem.contestId}-${sub.problem.index}`;
            const isSolved = sub.verdict === 'OK';

            if (isSolved && !globalSolvedProblems.has(problemId)) {
                globalSolvedProblems.add(problemId);
                const rating = sub.problem.rating;
                if (rating) {
                    const ratingStr = rating.toString();
                    ratingDist[ratingStr] = (ratingDist[ratingStr] || 0) + 1;
                }
            }

            for (let tag of sub.problem.tags) {
                if (!tagStats[tag]) {
                    tagStats[tag] = { attemptedSet: new Set(), solvedSet: new Set() };
                }
                tagStats[tag].attemptedSet.add(problemId);
                if (isSolved) {
                    tagStats[tag].solvedSet.add(problemId);
                }
            }
        }

        // --- 4. NOISE FILTERING & WEAKNESS IDENTIFICATION ---
        const analysisReport = Object.keys(tagStats).map(tag => {
            const attemptedCount = tagStats[tag].attemptedSet.size;
            const solvedCount = tagStats[tag].solvedSet.size;
            const winRate = attemptedCount === 0 ? 0 : ((solvedCount / attemptedCount) * 100);

            return {
                topic: tag,
                attempted: attemptedCount,
                solved: solvedCount,
                winRate: parseFloat(winRate.toFixed(2))
            };
        })
            .filter(stat => stat.attempted >= 5)
            .sort((a, b) => a.winRate - b.winRate);

        // --- 5. FETCH REAL RECOMMENDED PROBLEMS ---
        let recommendedProblems = [];

        if (analysisReport.length > 0) {
            const weakestTag = analysisReport[0].topic;

            const minTarget = userRating === 0 ? 800 : userRating;
            const maxTarget = userRating === 0 ? 1200 : userRating + 200;

            try {
                const problemsetResponse = await fetch('https://codeforces.com/api/problemset.problems');
                const problemsetData = await problemsetResponse.json();

                if (problemsetData.status === 'OK') {
                    const allProblems = problemsetData.result.problems;

                    recommendedProblems = allProblems.filter(p =>
                        p.tags.includes(weakestTag) &&
                        p.rating &&
                        p.rating >= minTarget && p.rating <= maxTarget &&
                        !globalSolvedProblems.has(`${p.contestId}-${p.index}`)
                    ).slice(0, 5);

                    recommendedProblems = recommendedProblems.map(p => ({
                        name: `${p.contestId}${p.index} - ${p.name}`,
                        rating: p.rating,
                        tags: p.tags,
                        link: `https://codeforces.com/contest/${p.contestId}/problem/${p.index}`
                    }));
                }
            } catch (err) {
                console.error("Failed to fetch problemset for recommendations", err);
            }
        }

        // --- 6. SEND UNIFIED PAYLOAD TO FLUTTER ---
        res.json({
            handle: handle,
            currentRating: userRating, 
            totalSubmissions: submissions.length,
            totalSolved: globalSolvedProblems.size,
            ratingDistribution: ratingDist,
            weakestTopicIdentified: analysisReport.length > 0 ? analysisReport[0].topic : "Unknown",
            recommendations: recommendedProblems,
            fullReport: analysisReport
        });

    } catch (error) {
        console.error("Error:", error);
        res.status(500).json({ error: "Internal Server Error" });
    }
});

// --- SERVER LISTENER (ONLY CALLED ONCE NOW) ---
app.listen(PORT, () => {
    console.log(`🚀 Server is running at http://localhost:${PORT}`);
});