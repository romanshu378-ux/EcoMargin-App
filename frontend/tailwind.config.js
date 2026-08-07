/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        brand: {
          50: '#f2fdf5',
          100: '#e1fbe9',
          500: '#10b981', // Emerald primary
          600: '#059669',
          900: '#064e3b'
        }
      }
    },
  },
  plugins: [],
}
