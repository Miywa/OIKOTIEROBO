*** Settings ***
Library    RPA.Browser.Selenium    auto_close=${False}
Library    RPA.PDF
Library    RPA.FileSystem
Library    RPA.Images
Library    Collections
Library    OperatingSystem
Library    DateTime 
#tän yläpuolella olevat asiat eli Settingsin-osiossa on kirjastoja.

*** Variables ***
#tän alapuolella olevat asiat eli Variables-osiossa määritellään muuttujat
${TE_WEBSITE}    https://paikat.te-palvelut.fi/tpt/
${SCREENSHOT_PATH}    C:/temp/screenshots-te/
${PDF_OUTPUT_PATH}    C:/temp/tyopaikka_linkit_ja_kuvakaappaukset.pdf

*** Tasks ***
#Tän alle tulee avainsanat eli noi ''otsikot''' ja niiden alle ryhmitellään ja nimetään koodilohkot eli toiminnallisuudet
Avaa ja käsittele Työpaikkailmoitusten Linkit ja Kuvakaappaukset
    Avaa Te-Verkkosivu
    Lisää Hakusanat
    Kerää Työpaikkailmoitusten Linkit
    Avaa Ensimmäiset 15 Linkkiä ja Ota Kuvakaappaukset
    Luo PDF HTML-sisällöstä

*** Keywords ***
Avaa Te-Verkkosivu
    Open Available Browser    ${TE_WEBSITE}

Lisää hakusanat
    Delete All Cookies
    Click Element When Visible    xpath://a[text()='Hyväksy kaikki evästeet'] 
    Input Text    id=sanahaku    IT
    Click Element    id=ammattialaDialogLink
    Click Element    id=4
    Click Element    xpath://div[contains(@class, 'clearfieldcircleWhite')]
    Input Text    id=sanahaku    IT
    Click Element    xpath=//*[@id="alueet"]
    Click Element    xpath=//*[@id="searchFormFieldArea"]/div[3]/div[2]/accordion/div[3]/tpt-autocomplete-municipality/ol/div[4]/li[2]/div
    Click Element    xpath=//*[@id="alueet"]
    Click Element    xpath=/html/body/tpt-root/main/tpt-main/div[1]/div[2]/div[1]/tpt-searchform/form/div/div/div[1]/div[3]/div[2]/accordion/div[3]/tpt-autocomplete-municipality/ol/div[4]/li[4]/div
    Input Text    id=alueet    Vantaa
    Press Keys    id=alueet    ENTER
    Click Element    xpath=//*[@id="toggleParameters"]/span
    Click Element If Visible    xpath=//*[@id="searchButton"]
    Wait Until Element Is Visible    xpath=//*[@id="list-top-row"]/select    timeout=10
    Click Element    xpath=//*[@id="list-top-row"]/select
    Select From List By Value    xpath=//*[@id="list-top-row"]/select    8

Kerää Työpaikkailmoitusten Linkit
    @{links}    Create List
    FOR    ${index}    IN RANGE    1    16
        ${link}    Get Element Attribute    xpath=(//*[@id="groupedList"]//a)[${index}]    href
        Append To List    ${links}    ${link}
    END
    Set Global Variable    ${JOB_LINKS}    ${links}

Avaa Ensimmäiset 15 Linkkiä ja Ota Kuvakaappaukset
    RPA.FileSystem.Create Directory    ${SCREENSHOT_PATH}   # Luo hakemisto, jos sitä ei ole ennen kuvankaappausta
    Log    Kuvakaappausten hakemisto luotu tai jo olemassa: ${SCREENSHOT_PATH}
    ${index}    Set Variable    1
    FOR    ${link}    IN    @{JOB_LINKS}
        Log    Avaa linkki ja ota kuvakaappaus: ${link}
        Go To    ${link}
        ${screenshot_path}    Set Variable    ${SCREENSHOT_PATH}screenshot_${index}.png
        Log    Tallennetaan kuvakaappaus polkuun: ${screenshot_path}
        Capture Page Screenshot    ${screenshot_path}
        ${index}    Evaluate    ${index} + 1
    END

Luo PDF HTML-sisällöstä
    ${html_content}    Set Variable    <html><body><h1>Työpaikkailmoitukset</h1>

    # Lisää linkit ja kuvakaappaukset HTML-sisältöön
    FOR    ${index}    IN RANGE    1    16
        ${link}    Set Variable    ${JOB_LINKS}[${index - 1}]
        ${screenshot}    Set Variable    ${SCREENSHOT_PATH}screenshot_${index}.png
        ${html_content}    Set Variable    ${html_content}<h2>Linkki ${index}</h2><p><a href="${link}">${link}</a></p>
        ${html_content}    Set Variable    ${html_content}<img src="${screenshot}" width="500">
    END

    ${html_content}    Set Variable    ${html_content}</body></html>
    HTML To PDF    ${html_content}    ${PDF_OUTPUT_PATH}
