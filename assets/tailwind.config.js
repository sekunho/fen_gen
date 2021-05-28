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
      }),
      height: {
        '1/8': '12.5%',
      },
      width: {
        '1/8': '12.5%',
      },
      gridTemplateColumns: {
        '4-1': '75% 25%'
      }
    },
  },
  variants: {
    extend: {},
  },
  plugins: [],
}
