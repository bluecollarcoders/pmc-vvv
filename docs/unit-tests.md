# Unit Tests

For each site you provision, e.g. Sportico, you may run the theme and pmc-plugins unit tests by following the steps below. Do steps 1-3 once, and steps 4+ for each provisioned site, e.g. Sportico, WWD, etc.. The basic concept here is that we copy the testing tools from wordpress-develop into each provisioned site.

NOTE, Ideally, we could provision wordpress-trunk into VVV via [custom-site-template-develop](https://github.com/Varying-Vagrant-Vagrants/custom-site-template-develop) (by setting skip_provisioning: false in config.yml) as it provides phpunit, test database, and the wp test suite. However, it forces you to use the latest (unreleased) version. Using its master branch can/has lead to issues when running tests with our pmc-unit-test bootstrap.php. Due to this, we setup the test environment manually (steps 1-3 below).

NOTE the Second. If you're using php8 and phpunit9, you can install a parallel phpunit9 installation. Please [see the faq](../docs/faq.md#phpunit-with-php-8).

1. Install phpunit
    ```bash
    # If not in VM...
    $ vagrant ssh
    ```
   In VM...
    ```bash
    $ sudo mkdir -p /usr/share/php/phpunit
    $ cd /usr/share/php/phpunit
    $ sudo composer require --dev phpunit/phpunit ^7 --update-with-all-dependencies
    $ sudo ln -sf /usr/share/php/phpunit/vendor/bin/phpunit /usr/bin/phpunit
    ```
1. Get the WP Test Suite
    ```bash
    # If not in VM...
    $ vagrant ssh
    ```
   In VM...
    ```bash
    # As of Sept 2021 pmc-unit-test is compatible with WP 5.8
    # This is due to https://core.trac.wordpress.org/changeset/51559, as pmc-unit-test is not yet compatible with yoast/phpunit-polyfills
    $ cd ~/
    $ git clone --depth 1 --branch 5.8.1 git@github.com:WordPress/wordpress-develop.git
    ```
1. Copy the WP Test Suite per site
    ```bash
    # If not in VM...
    $ vagrant ssh
    ```
   In VM...
    ```bash
    $ cp -r ~/wordpress-develop/tests/ /srv/www/sportico-com/public_html/
    ```
1. Create `wp-tests-config.php` per site
    ```bash
    # If not in VM...
    $ vagrant ssh
    ```
   In VM...
    ```bash
    $ cp ~/wordpress-develop/wp-tests-config-sample.php /srv/www/sportico-com/public_html/wp-tests-config.php
    ```
    1. open the file you copied `wp-tests-config.php` in your editor / IDE of choice.
    1. change line 4 to `define( 'ABSPATH', dirname( __FILE__ ) . '/' );`
    1. Configure `DB_*` named constants: NOTE the DB_NAME should match your 
       provisioned site (see wp-config.php)
        ```
        define( 'DB_NAME', 'sportico-com' );
        define( 'DB_USER', 'wp' );
        define( 'DB_PASSWORD', 'wp' );
        define( 'DB_HOST', 'localhost' );
        ```
    1. Add the following constants
        ```
        define( 'PMC_IS_VIP_GO_SITE', true );
        define( 'VIP_GO_APP_ENVIRONMENT', 'development' );
        ```
1. Run tests
    1. Note, we must tell PHPUnit where our test bootstraps are located. Note, this must be done each time you SSH into vagrant (See below PHPStorm docs to automate this). Note, change `sportico-com` to the site you're testing within.
    1. Note, if xdebug is enabled your tests will run VERY slowly. See 
       [xDebug documentation](https://varyingvagrantvagrants.org/docs/en-US/references/xdebug/ ). Only enable xdebug while testing if you wish to step-through debug your tests or generate a code coverage report.


    ```bash
    # If not in VM...
    $ vagrant ssh
    ```
    
    In VM...
    ```bash
    You can add these variables to your bash, but make sure they are at the bottom of ~/.bash_profile as not to conflict with vvv's settings.
    $ export PMC_PHPUNIT_BOOTSTRAP=/srv/www/sportico-com/public_html/wp-content/plugins/pmc-plugins/pmc-unit-test/bootstrap.php
    $ export WP_TESTS_DIR=/srv/www/sportico-com/public_html/tests/phpunit

    # If you edited ~/.bash_profile reload it.
    $ source ~/.bash_profile

    # Navigate to a pmc-plugin or a theme where `phpunit.xml` exists. E.g.
    $ cd /srv/www/sportico-com/public_html/wp-content/plugins/pmc-plugins/pmc-piano/

    # Run tests
    $ phpunit
    ```

To run tests in PHPStorm and/or Step-Through debug tests, see here: https://confluence.pmcdev.io/x/sIyzB (this replaces steps 4-7 above)

![Testing in PHPStorm](./Testing-in-PHPStorm.png)
