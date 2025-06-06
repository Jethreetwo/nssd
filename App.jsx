import { useState } from 'react'
import ScheduleSelector from 'react-schedule-selector'
import nssdLogo from './assets/nssd-logo.png'
import { Button } from '@/components/ui/button.jsx'
import './App.css'

function App() {
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    referral: '',
    availability: [],
    activities: []
  });
  
  const [submitStatus, setSubmitStatus] = useState({
    isSubmitting: false,
    isSuccess: false,
    isError: false,
    message: ''
  });

  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setFormData({
      ...formData,
      [name]: value
    });
  };

  const handleAvailabilityChange = (newAvailability) => {
    setFormData({
      ...formData,
      availability: newAvailability
    });
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setSubmitStatus({
      isSubmitting: true,
      isSuccess: false,
      isError: false,
      message: 'Submitting your application...'
    });
    
    try {
      const response = await fetch('http://localhost:5000/api/applications', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(formData),
      });
      
      const data = await response.json();
      
      if (!response.ok) {
        throw new Error(data.error || 'Failed to submit application');
      }
      
      setSubmitStatus({
        isSubmitting: false,
        isSuccess: true,
        isError: false,
        message: 'Application submitted successfully!'
      });
      
      // Reset form after successful submission
      setFormData({
        name: '',
        email: '',
        referral: '',
        availability: [],
        activities: []
      });
      
    } catch (error) {
      setSubmitStatus({
        isSubmitting: false,
        isSuccess: false,
        isError: true,
        message: error.message || 'An error occurred while submitting your application'
      });
    }
  };

  // Sample activities for the checkbox selection
  const activityOptions = [
    'Game Nights',
    'Hiking Trips',
    'Study Groups',
    'Movie Screenings',
    'Beach Outings',
    'Campus Tours',
    'Sports Events',
    'Workshops'
  ];

  const handleActivityChange = (activity) => {
    if (formData.activities.includes(activity)) {
      setFormData({
        ...formData,
        activities: formData.activities.filter(item => item !== activity)
      });
    } else {
      setFormData({
        ...formData,
        activities: [...formData.activities, activity]
      });
    }
  };

  return (
    <div className="min-h-screen bg-background p-4 md:p-8">
      <div className="max-w-4xl mx-auto">
        {/* Logo and Header */}
        <div className="flex justify-center mb-8">
          <img src={nssdLogo} alt="Not So Socially Dead Logo" className="h-24 md:h-32" />
        </div>
        
        {/* Form Container */}
        <div className="bg-card rounded-lg shadow-lg p-6 md:p-8">
          <h1 className="text-2xl md:text-3xl font-bold text-center mb-6">Join Not So Socially Dead</h1>
          
          {/* Status Messages */}
          {submitStatus.isSuccess && (
            <div className="mb-6 p-4 bg-green-100 border border-green-400 text-green-700 rounded">
              {submitStatus.message}
            </div>
          )}
          
          {submitStatus.isError && (
            <div className="mb-6 p-4 bg-red-100 border border-red-400 text-red-700 rounded">
              {submitStatus.message}
            </div>
          )}
          
          <form onSubmit={handleSubmit} className="space-y-6">
            {/* Name Field */}
            <div className="space-y-2">
              <label htmlFor="name" className="block text-sm font-medium">
                Full Name
              </label>
              <input
                type="text"
                id="name"
                name="name"
                value={formData.name}
                onChange={handleInputChange}
                className="w-full px-3 py-2 border border-input rounded-md"
                required
              />
            </div>
            
            {/* Email Field */}
            <div className="space-y-2">
              <label htmlFor="email" className="block text-sm font-medium">
                UCSD Email
              </label>
              <input
                type="email"
                id="email"
                name="email"
                value={formData.email}
                onChange={handleInputChange}
                className="w-full px-3 py-2 border border-input rounded-md"
                placeholder="example@ucsd.edu"
                pattern=".+@ucsd\.edu"
                title="Please enter a valid UCSD email address"
                required
              />
              <p className="text-xs text-muted-foreground">Must be a valid UCSD email address</p>
            </div>
            
            {/* Referral Field */}
            <div className="space-y-2">
              <label htmlFor="referral" className="block text-sm font-medium">
                Referred By (Optional)
              </label>
              <input
                type="text"
                id="referral"
                name="referral"
                value={formData.referral}
                onChange={handleInputChange}
                className="w-full px-3 py-2 border border-input rounded-md"
              />
            </div>
            
            {/* Availability Calendar */}
            <div className="space-y-2">
              <label className="block text-sm font-medium">
                Weekly Availability
              </label>
              <div className="border border-input rounded-md p-4 overflow-x-auto">
                <p className="text-sm mb-2">Select all time slots when you're available:</p>
                <div className="min-w-[600px]">
                  <ScheduleSelector
                    selection={formData.availability}
                    numDays={7}
                    minTime={8}
                    maxTime={22}
                    hourlyChunks={2}
                    onChange={handleAvailabilityChange}
                    columnGap="2px"
                    rowGap="2px"
                    dateFormat="ddd"
                    timeFormat="h:mm a"
                  />
                </div>
                <p className="text-xs text-muted-foreground mt-2">Click and drag to select multiple time slots</p>
              </div>
            </div>
            
            {/* Activity Selection */}
            <div className="space-y-2">
              <label className="block text-sm font-medium">
                Interested Activities
              </label>
              <div className="grid grid-cols-2 md:grid-cols-3 gap-2">
                {activityOptions.map((activity) => (
                  <div key={activity} className="flex items-center">
                    <input
                      type="checkbox"
                      id={`activity-${activity}`}
                      checked={formData.activities.includes(activity)}
                      onChange={() => handleActivityChange(activity)}
                      className="mr-2"
                    />
                    <label htmlFor={`activity-${activity}`} className="text-sm">
                      {activity}
                    </label>
                  </div>
                ))}
              </div>
            </div>
            
            {/* Submit Button */}
            <div className="pt-4">
              <Button 
                type="submit" 
                className="w-full"
                disabled={submitStatus.isSubmitting}
              >
                {submitStatus.isSubmitting ? 'Submitting...' : 'Submit Application'}
              </Button>
            </div>
          </form>
        </div>
      </div>
    </div>
  )
}

export default App

