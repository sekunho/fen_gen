module.exports = {
  // mode: 'jit',
  purge: [
    './index.html',
    './src/*.js',
    './assets/sass/*.scss'
  ],
  darkMode: 'class', // or 'media' or 'class'
  theme: {
    extend: {
      fontFamily: theme => ({
        sans: ['Inter', 'sans-serif']
      })
    },
  },
  variants: {
    extend: {},
  },
  plugins: [],
}
