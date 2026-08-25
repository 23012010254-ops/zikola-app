import React, { useState, useEffect, useRef } from 'react';
import { motion } from 'motion/react';
import { ArrowLeft, Send, Paperclip, Camera, Mic, MoreVertical } from 'lucide-react';

interface ChatScreenProps {
  navigateTo: (screen: string) => void;
  doctor: any;
}

export default function ChatScreen({ navigateTo, doctor }: ChatScreenProps) {
  const [messages, setMessages] = useState([
    {
      id: 1,
      text: 'Halo! Selamat datang di konsultasi online. Saya Dr. Zaky, siap membantu Anda hari ini.',
      sender: 'doctor',
      timestamp: '10:15',
      type: 'text'
    },
    {
      id: 2,
      text: 'Silakan ceritakan keluhan atau pertanyaan yang ingin Anda sampaikan.',
      sender: 'doctor',
      timestamp: '10:15',
      type: 'text'
    }
  ]);
  
  const [newMessage, setNewMessage] = useState('');
  const [isTyping, setIsTyping] = useState(false);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
  };

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  const sendMessage = () => {
    if (newMessage.trim()) {
      const userMessage = {
        id: messages.length + 1,
        text: newMessage,
        sender: 'user',
        timestamp: new Date().toLocaleTimeString('id-ID', { 
          hour: '2-digit', 
          minute: '2-digit' 
        }),
        type: 'text'
      };
      
      setMessages([...messages, userMessage]);
      setNewMessage('');
      setIsTyping(true);
      
      // Simulate doctor response
      setTimeout(() => {
        const doctorResponse = {
          id: messages.length + 2,
          text: 'Terima kasih sudah menceritakan keluhannya. Berdasarkan yang Anda sampaikan, saya akan memberikan beberapa saran...',
          sender: 'doctor',
          timestamp: new Date().toLocaleTimeString('id-ID', { 
            hour: '2-digit', 
            minute: '2-digit' 
          }),
          type: 'text'
        };
        setMessages(prev => [...prev, doctorResponse]);
        setIsTyping(false);
      }, 2000);
    }
  };

  if (!doctor) {
    navigateTo('consultation');
    return null;
  }

  return (
    <div className="min-h-screen bg-gray-50 flex flex-col">
      {/* Header */}
      <div className="bg-white px-4 pt-14 pb-4 border-b border-gray-100 flex-shrink-0">
        <div className="flex items-center space-x-3">
          <motion.button
            onClick={() => navigateTo('consultation')}
            className="p-2 rounded-xl bg-gray-100"
            whileTap={{ scale: 0.95 }}
          >
            <ArrowLeft className="w-5 h-5 text-gray-600" />
          </motion.button>
          
          <div className="w-10 h-10 bg-blue-100 rounded-full flex items-center justify-center">
            <span className="text-lg">{doctor.image}</span>
          </div>
          
          <div className="flex-1">
            <h2 className="text-gray-900 font-heading font-bold text-lg">
              {doctor.name}
            </h2>
            <div className="flex items-center space-x-2">
              <div className="w-2 h-2 bg-green-500 rounded-full" />
              <span className="text-green-600 font-body text-sm font-medium">
                Online
              </span>
            </div>
          </div>
          
          <button className="p-2 rounded-xl bg-gray-100">
            <MoreVertical className="w-5 h-5 text-gray-600" />
          </button>
        </div>
      </div>

      {/* Messages */}
      <div className="flex-1 overflow-y-auto p-4 space-y-4">
        {messages.map((message) => (
          <motion.div
            key={message.id}
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            className={`flex ${message.sender === 'user' ? 'justify-end' : 'justify-start'}`}
          >
            <div className={`max-w-xs lg:max-w-md px-4 py-3 rounded-2xl ${
              message.sender === 'user'
                ? 'bg-blue-500 text-white rounded-br-lg'
                : 'bg-white text-gray-900 rounded-bl-lg shadow-sm'
            }`}>
              <p className="font-body text-sm leading-relaxed">
                {message.text}
              </p>
              <p className={`text-xs mt-1 ${
                message.sender === 'user' ? 'text-blue-100' : 'text-gray-500'
              }`}>
                {message.timestamp}
              </p>
            </div>
          </motion.div>
        ))}
        
        {/* Typing indicator */}
        {isTyping && (
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            className="flex justify-start"
          >
            <div className="bg-white rounded-2xl rounded-bl-lg shadow-sm px-4 py-3">
              <div className="flex space-x-1">
                <motion.div
                  className="w-2 h-2 bg-gray-400 rounded-full"
                  animate={{ scale: [1, 1.2, 1] }}
                  transition={{ duration: 0.6, repeat: Infinity, delay: 0 }}
                />
                <motion.div
                  className="w-2 h-2 bg-gray-400 rounded-full"
                  animate={{ scale: [1, 1.2, 1] }}
                  transition={{ duration: 0.6, repeat: Infinity, delay: 0.2 }}
                />
                <motion.div
                  className="w-2 h-2 bg-gray-400 rounded-full"
                  animate={{ scale: [1, 1.2, 1] }}
                  transition={{ duration: 0.6, repeat: Infinity, delay: 0.4 }}
                />
              </div>
            </div>
          </motion.div>
        )}
        <div ref={messagesEndRef} />
      </div>

      {/* Quick Responses */}
      <div className="px-4 py-2 border-t border-gray-100 bg-white">
        <div className="flex space-x-2 overflow-x-auto pb-2">
          {[
            'Terima kasih dokter',
            'Saya mengerti',
            'Apakah ada efek samping?',
            'Berapa lama pengobatan?'
          ].map((response, index) => (
            <motion.button
              key={index}
              onClick={() => setNewMessage(response)}
              className="flex-shrink-0 bg-gray-100 hover:bg-gray-200 text-gray-700 px-3 py-2 rounded-full text-sm font-body font-medium transition-colors"
              whileTap={{ scale: 0.95 }}
            >
              {response}
            </motion.button>
          ))}
        </div>
      </div>

      {/* Message Input */}
      <div className="bg-white border-t border-gray-100 p-4 flex-shrink-0">
        <div className="flex items-center space-x-3">
          <button className="p-2 text-gray-500 hover:text-gray-700">
            <Paperclip size={20} />
          </button>
          
          <div className="flex-1 relative">
            <input
              type="text"
              value={newMessage}
              onChange={(e) => setNewMessage(e.target.value)}
              onKeyPress={(e) => e.key === 'Enter' && sendMessage()}
              placeholder="Ketik pesan..."
              className="w-full bg-gray-100 rounded-full px-4 py-3 font-body text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 focus:bg-white transition-all"
            />
          </div>
          
          <button className="p-2 text-gray-500 hover:text-gray-700">
            <Camera size={20} />
          </button>
          
          <button className="p-2 text-gray-500 hover:text-gray-700">
            <Mic size={20} />
          </button>
          
          <motion.button
            onClick={sendMessage}
            className={`p-3 rounded-full transition-all ${
              newMessage.trim()
                ? 'bg-blue-500 text-white hover:bg-blue-600'
                : 'bg-gray-200 text-gray-400'
            }`}
            whileTap={{ scale: 0.95 }}
            disabled={!newMessage.trim()}
          >
            <Send size={18} />
          </motion.button>
        </div>
      </div>
    </div>
  );
}