RobotRecorder Vagrant
=====================

This is package provides a vagrant provision for a single instance Selenium
server, which can records tests (with audio) and save the results as a
flv-file.

::
    $ git clone https://github.com/datakurre/robotrecorder_vagrant.git
    $ cd robotrecorder_vagrant
    $ vagrant up

Limitations: The current configuration runs the tests on Iceweasel
(Firefox for Debian). Only one active window at time can be recorded.

The toolchain is based on: Selenium-server, Xvfb, x11vnc, vnc2flc and
alsa (arecord).


Robot Framework example
-----------------------

./bootstrap.py::

    $ curl -O http://downloads.buildout.org/2/bootstrap.py

./buildout.cfg::

    [buildout]
    parts = pybot

    [pybot]
    recipe = zc.recipe.egg
    eggs =
        robotframework
        robotframework-selenium2library

Running the buildout::

    $ python bootstrap.py
    $ bin/buildout

example.robot::

    *** Settings ***

    Library  Selenium2Library

    Test Setup  Open browser  about:  remote_url=http://localhost:4444/wd/hub
    Test Teardown  Close all browsers

    *** Test cases ***

    We should be on the first page
        Go to  http://www.google.com/
        Input text  q  Plone
        Wait until page contains element  xpath=//a[@href='http://plone.org/']
        Click link  xpath=//a[@href='http://plone.org/']
        Wait until location is  http://plone.org/
        Title should be  Plone CMS: Open Source Content Management

    *** Keywords ***

    Wait until location is
        [Arguments]  ${expected_url}
        ${timeout} =  Get Selenium timeout
        ${implicit_wait} =  Get Selenium implicit wait
        Wait until keyword succeeds  ${timeout}  ${implicit_wait}
        ...                          Location should be  ${expected_url}

Executing the test::

    $ bin/pybot example.robot

The test execution should result an "out.TIMESTAMP.flv" file in the current
vagrant working directory.


Plone Example
-------------

./bootstrap.py::

    $ curl -O http://downloads.buildout.org/2/bootstrap.py

./buildout.cfg::

    [buildout]
    extends = http://dist.plone.org/release/4.3-latest/versions.cfg
    parts = pybot

    [pybot]
    recipe = zc.recipe.egg
    eggs =
        Pillow
        plone.app.robotframework[speak]
    scripts = pybot

Running the buildout::

    $ python bootstrap.py
    $ bin/buildout

./example.robot::

    *** Settings ***

    Resource  plone/app/robotframework/server.robot
    Resource  plone/app/robotframework/annotate.robot
    Resource  plone/app/robotframework/speak.robot

    Suite Setup  Setup
    Suite Teardown  Teardown

    *** Keywords ***

    Setup
        Setup Plone site  plone.app.robotframework.testing.SPEAKJS_ROBOT_TESTING
        Import library  Remote  ${PLONE_URL}/RobotRemote

    Teardown
        Teardown Plone Site

    *** Test Cases ***

    Portal factory add menu

        Enable autologin as  Contributor
        Set autologin username  John Doe
        Go to  ${PLONE_URL}

        Speak  Ok. Hello. I'm John Doe.
        Sleep  2s
        ${pointer} =  Add pointer  user-name
        Sleep  2s
        Remove elements  ${pointer}

        Speak  I want to add some content into my site.
        Sleep  4s

        Click link  css=#plone-contentmenu-factories dt a
        Element should be visible
        ...    css=#plone-contentmenu-factories dd.actionMenuContent

        ${dot1} =  Add dot
        ...    css=#plone-contentmenu-factories dt a  1

        ${note1} =  Add note
        ...    css=#plone-contentmenu-factories
        ...    At first, click Add new… to open the menu
        ...    width=180  position=left

        Speak  At first, I click the Add new menu.
        Sleep  4s

        ${dot2} =  Add dot
        ...    css=#plone-contentmenu-factories dd.actionMenuContent  2
        ${note2} =  Add note
        ...    css=#plone-contentmenu-factories dd.actionMenuContent
        ...    Then click any option to add new content
        ...    width=180  position=left

        Speak  Then I select the option, which I would like to add.
        Sleep  4s

        Align elements horizontally  ${dot2}  ${dot1}
        Align elements horizontally  ${note2}  ${note1}

        Capture and crop page screenshot  add-new-menu.png
        ...    contentActionMenus
        ...    css=#plone-contentmenu-factories dd.actionMenuContent
        ...    ${dot1}  ${note1}  ${dot2}  ${note2}

        Remove elements  ${dot1}  ${note1}  ${dot2}  ${note2}

        Speak  Next, I will select page to add a new document.
        Sleep  1s
        Add pointer  css=a#document
        Sleep  2s
        Click link  css=a#document

        Wait Until Page Contains Element  css=#archetypes-fieldname-title input

        ${dot1} =  Add dot  css=input#title  1
        ${note1} =  Add note  css=input#title
        ...    Enter document title
        ...    width=200  position=right

        Speak  At first, I enter the title.
        Sleep  3s

        Input Text  title  This is the title

        ${dot2} =  Add dot  css=textarea#description  2
        ${note2} =  Add note  css=textarea#description
        ...    Enter document summary or description
        ...    width=200  position=right

        Speak  Then, I enter some summary or description for the page.
        Sleep  4s

        Input Text  description  This is the summary.

        Capture and crop page screenshot  add-new-document-1.png
        ...    archetypes-fieldname-title  archetypes-fieldname-description
        ...    ${dot1}  ${note1}  ${dot2}  ${note2}

        Speak  Next, I just click save. I will add the rest later.
        Sleep  2s

        Mouse over  css=input.context

        ${dot3} =  Add dot  css=input.context  3
        ${note3} =  Add note  css=input.context
        ...    Click save
        ...    width=90  position=right

        Sleep  2s

        Capture and crop page screenshot  add-new-document-2.png
        ...    css=input.context  css=input.standalone
        ...    ${dot3}  ${note3}

        Capture page screenshot  add-new-document.png
        Remove elements  ${dot1}  ${note1}  ${dot2}  ${note2}  ${dot3}  ${note3}

        Add pointer  css=input.context
        Sleep  1s

        Click button  Save
        Element should contain  css=#parent-fieldname-title  This is the title

        Speak  Well, that was easy.
        Sleep  2s
        Speak  Thank you.
        Sleep  4s

        Update element style  visual-portal-wrapper  -moz-transition  all 2s
        Update element style  visual-portal-wrapper  -moz-transform  rotate(180deg) scale(0)
        Update element style  visual-portal-wrapper  margin-top  50%
        Sleep  3s

Executing the test::

    $ ZSERVER_HOST=HOST_LAN_IP bin/pybot -v ZOPE_HOST:HOST_LAN_IP -v REMOTE_URL:http://localhost:4444/wd/hub example.robot

Replace HOST_LAN_IP with a such IP or hostname of your host machine, which is
also accessible from the vagrant guest.

The test execution should result an "out.TIMESTAMP.flv" file in the current
vagrant working directory: http://www.youtube.com/watch?v=DAJ30qldJak
