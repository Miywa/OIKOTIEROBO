*** Settings ***
Library    RPA.Browser.Selenium    auto_close=${False}
Library    RPA.PDF
Library    RPA.FileSystem
Library    RPA.Images
Library    Collections
Library    OperatingSystem

*** Variables ***
${TE_WEBSITE}           https://paikat.te-palvelut.fi/tpt/
${BASE_OUTPUT_PATH}     C:/Users/tansk/OIKOTIEROBO/output
${SCREENSHOT_PATH}      ${BASE_OUTPUT_PATH}/screenshots-te
${PDF_OUTPUT_PATH}      ${BASE_OUTPUT_PATH}/tyopaikka_linkit_ja_kuvakaappaukset.pdf

*** Tasks ***
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
    Wait Until Element Is Visible    xpath=//*[@id="list-top-row"]/select    timeout=15
    Click Element    xpath=//*[@id="list-top-row"]/select
    Select From List By Value    xpath=//*[@id="list-top-row"]/select    8

Kerää Työpaikkailmoitusten Linkit
    @{links}    Create List
    FOR    ${index}    IN RANGE    1    16
        ${link}    Get Element Attribute    xpath=(//*[@id="groupedList"]//a)[${index}]    href
        Log    Found link: ${link}
        Append To List    ${links}    ${link}
    END
    Log    Total links collected: ${links}
    Set Global Variable    ${JOB_LINKS}    ${links}

Avaa Ensimmäiset 15 Linkkiä ja Ota Kuvakaappaukset
    # Ensure that the screenshots directory is created
    RPA.FileSystem.Create Directory    ${SCREENSHOT_PATH}
    Log    Screenshots directory created or already exists: ${SCREENSHOT_PATH}

    ${index}    Set Variable    1
    FOR    ${link}    IN    @{JOB_LINKS}
        Log    Opening link ${index}: ${link}
        
        # Navigate to each link
        Go To    ${link}
        
        # Wait for the page to load completely
        Wait Until Page Contains Element    xpath=//body    timeout=20
        Log    Page loaded for link ${index}
        Sleep    2s  # Additional delay for dynamic content
        
        # Capture screenshot directly without intermediate variable
        Run Keyword And Ignore Error    Capture Page Screenshot    ${SCREENSHOT_PATH}/screenshot_${index}.png
        
        # Verify that the screenshot file was created
        File Should Exist    ${SCREENSHOT_PATH}/screenshot_${index}.png
        Log    Screenshot saved successfully: ${SCREENSHOT_PATH}/screenshot_${index}.png  # Confirm save
        
        # Increment index for the next screenshot filename
        ${index}    Evaluate    ${index} + 1
    END

Luo PDF HTML-sisällöstä
    ${html_content}    Set Variable    <html><body><h1>Työpaikkailmoitukset</h1>
    FOR    ${index}    IN RANGE    1    16
        ${link}    Set Variable    ${JOB_LINKS}[${index - 1}]
        
        # Correctly construct the screenshot path with a slash
        ${screenshot}    Set Variable    ${SCREENSHOT_PATH}/screenshot_${index}.png
        
        ${html_content}    Set Variable    ${html_content}<h2>Linkki ${index}</h2><p><a href="${link}">${link}</a></p>
        ${html_content}    Set Variable    ${html_content}<img src="${screenshot}" width="500">
    END
    ${html_content}    Set Variable    ${html_content}</body></html>
    HTML To PDF    ${html_content}    ${PDF_OUTPUT_PATH}
    Log To Console    PDF generated at: ${PDF_OUTPUT_PATH}
