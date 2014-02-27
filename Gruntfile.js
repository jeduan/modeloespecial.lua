module.exports = function(grunt) {
  grunt.initConfig({
    bower: grunt.file.readJSON('bower.json'),

    copy: {
      release: {
        files: [
          {
            src: [
              'vendor/**/*.lua', '!**/*spec.lua', '!**/*test.lua',
              '!**/performance/*'
            ],
            dest: 'build/',
          },
          {
            src: '<%= bower.name %>.lua',
            dest: 'build/vendor/<%= bower.name %>/'
          }
        ]
      }
    },

    clean: {
      release: ['build'],
      postRelease: ['build/vendor']
    },

    compress: {
      release: {
        options: {
          archive: 'build/<%= bower.name %>-<%= bower.version %>.zip',
        },
        files: [
          {
            expand: true,
            cwd: 'build',
            src: ['vendor/**/*']
          }
        ]
      }
    },

    release: {
      options: {
        file: 'bower.json',
        npm: false,
        tagName: 'v<%= version %>',
        github: {
          repo: 'jeduan/corona-analytics-mixpanel',
          usernameVar: 'GITHUB_TOKEN',
          passwordVar: 'GITHUB_PASSWORD'
        }
      }
    }
  })

  grunt.registerTask('ziprelease', [
    'clean:release', 'copy:release', 'compress:release', 'clean:postRelease'
  ])

  grunt.loadNpmTasks('grunt-contrib-copy')
  grunt.loadNpmTasks('grunt-contrib-clean')
  grunt.loadNpmTasks('grunt-contrib-compress')
  grunt.loadNpmTasks('grunt-release')
}
