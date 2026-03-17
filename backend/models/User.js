const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
    email: { 
        type: String, 
        required: true, 
        unique: true // Prevents duplicate accounts
    },
    password: { 
        type: String, 
        required: true 
    },
    codeforcesHandle: { 
        type: String, 
        required: true 
    },
    lastSubmissionId: { 
        type: Number, 
        default: 0 // We will use this to optimize API calls later!
    },
    createdAt: { 
        type: Date, 
        default: Date.now 
    }
});

// Export the blueprint so your main server can use it
module.exports = mongoose.model('User', userSchema);