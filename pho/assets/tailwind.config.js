module.exports = {
  purge: [
    '../lib/**/*.ex',
    '../lib/**/*.leex',
    '../lib/**/*.eex',
    '../lib/**/*.sface',
    './js/**/*.js'
  ],
  darkMode: false, // or 'media' or 'class'
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
