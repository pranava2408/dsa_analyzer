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
    },

    // --- NEW FIELDS FOR 2-STEP VERIFICATION ---
    isVerified: {
        type: Boolean,
        default: false
    },
    otp: {
        type: String,
        required: false // Not required because verified users won't have an OTP
    },
    otpExpires: {
        type: Date,
        required: false
    }
});

// Export the blueprint so your main server can use it
module.exports = mongoose.model('User', userSchema);