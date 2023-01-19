*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.Dialogs
Library             RPA.Robocloud.Items
Library             RPA.Archive
Library             RPA.Hubspot
Library             OperatingSystem
Library             RPA.Dialogs
Library             RPA.Robocorp.Vault


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    Download the csv file
    @{robot-orders} =    Read the csv file and return a table
    FOR    ${row}    IN    @{robot-orders}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Submit the order
        ${pdf} =    Store the receipt as a PDF file    ${row}
        ${screenshot} =    Take a screenshot of the robot    ${row}
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${row}
        Go to order another robot
    END
    Create a ZIP file of the receipts
    Cleanup
    [Teardown]    Close the browser


*** Keywords ***
Open the robot order website
    Add text input    url    label=Robot Order URL
    ${response} =    Run dialog
    Open Available Browser    ${response.url}

Download the csv file
    ${url} =    Get Secret    downloadurl

    Download    ${url}[robots]    overwrite=True

Read the csv file and return a table
    ${robot-orders} =    Read Table From Csv    orders.csv    header=True

    FOR    ${robot-order}    IN    @{robot-orders}
        Log    ${robot-order}[Order number]
    END
    RETURN    @{robot-orders}

Close the annoying modal
    Click Button    Yep

Fill the form
    [Arguments]    ${row}
    Select From List By Value    head    ${row}[Head]
    Click Button    id-body-${row}[Body]
    Input Text    class:form-control    ${row}[Legs]
    Input Text    address    ${row}[Address]

Preview the robot
    Click Button    preview

Submit the order
    Click Button    order
    ${error} =    Does Page Contain Element    class:alert.alert-danger
    WHILE    ${error}
        Click Button    order
        ${error} =    Does Page Contain Element    class:alert.alert-danger
    END

Store the receipt as a PDF file
    [Arguments]    ${row}
    Wait Until Element Is Visible    id:receipt
    ${receipt_html} =    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt_html}    ${OUTPUT_DIR}${/}receipts${/}receipt${row}[Order number].pdf
    RETURN    ${OUTPUT_DIR}${/}receipts${/}receipt${row}[Order number].pdf

Take a screenshot of the robot
    [Arguments]    ${row}
    ${robot-screenshot} =    Screenshot
    ...    robot-preview-image
    ...    ${OUTPUT_DIR}${/}screenshots${/}screenshot${row}[Order number].png
    RETURN    ${robot-screenshot}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${row}

    ${files} =    Create List
    ...    ${OUTPUT_DIR}${/}screenshots${/}screenshot${row}[Order number].png

    Add Files To PDF    ${files}    ${OUTPUT_DIR}${/}receipts${/}receipt${row}[Order number].pdf    ${True}

Go to order another robot
    Click Button    order-another

Create a ZIP file of the receipts
    ${zip_file_name} =    Set Variable    ${OUTPUT_DIR}/Receipts.zip
    Archive Folder With Zip
    ...    ${OUTPUT_DIR}${/}receipts
    ...    ${zip_file_name}

Cleanup
    Remove Directory    ${OUTPUT_DIR}${/}screenshots    True
    Remove Directory    ${OUTPUT_DIR}${/}receipts    True

Close the browser
    Close Browser
