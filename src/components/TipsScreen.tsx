import React from 'react';

// This component is no longer used in the app routing
// It has been replaced by direct navigation to consultation and parent-guide
export default function TipsScreen() {
  return (
    <div className="min-h-screen bg-gray-50 flex items-center justify-center">
      <div className="text-center">
        <h1 className="text-xl font-heading font-bold text-gray-900 mb-2">
          Page Not Found
        </h1>
        <p className="text-gray-600 font-body">
          This page is no longer available.
        </p>
      </div>
    </div>
  );
}