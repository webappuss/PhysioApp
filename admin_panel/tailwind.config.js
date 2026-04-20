/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,ts,jsx,tsx}'],
  theme: {
    extend: {
      colors: {
        brand: {
          50:  '#e6f2ff',
          100: '#b3d6ff',
          500: '#1A6FD4',
          600: '#155bb0',
          700: '#104490',
        },
        teal: {
          500: '#00B4A6',
          600: '#009688',
        },
      },
    },
  },
  plugins: [
    require('@tailwindcss/forms'),
  ],
}
