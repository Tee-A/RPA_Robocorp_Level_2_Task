*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library     RPA.Browser.Selenium
Library     RPA.Tables
Library     RPA.PDF
Library     RPA.FileSystem
Library     RPA.HTTP
Library     RPA.Archive
Library     RPA.Dialogs
Library     RPA.Robocorp.Vault


*** Keywords ***
Open Robot Ordering Website
    Log     Opening the robot ordering website
    ${secrt}=    RPA.Robocorp.Vault.Get Secret    site
    Log     ${secrt}[url_location]
    Open Available Browser      ${secrt}[url_location]

*** Keywords ***
Get orders
    [Arguments]     ${order_path}
    Log             Getting Orders
    Download        ${order_path}      overwrite=True
    ${orders}=      Read table from CSV    orders.csv   header=True
    [Return]        ${orders}

*** Keywords ***
Close the annoying modal
    Log  Closing Icon
    Click Element When Visible      xpath://button[normalize-space()='OK']

*** Keywords ***
Fill form
    [Arguments]     ${order}
    Select From List By Value    id:head    ${order}[Head]
    Select Radio Button    body    ${order}[Body]
    Input Text    xpath://input[@placeholder='Enter the part number for the legs']      ${order}[Legs]
    Input Text    id:address    ${order}[Address]

*** Keywords ***
Preview the Robot
    Click Button    id:preview
    Sleep           2

*** Keywords ***
Submit the order
    Log  Submit the order
    Wait Until Keyword Succeeds    10x    1s    Assert Order Success

*** Keywords ***
Assert Order Success
    Click Button        id:order
    Wait Until Element Is Visible       id:receipt

*** Keywords ***
Store the receipt as a PDF file
    [Arguments]    ${order}
    Set Local Variable    ${OrderNumber}    ${order}[Order number]
    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    Set Local Variable    ${path_receipt}       ${CURDIR}${/}receipts${/}OrderNumber_${OrderNumber}.pdf
    Html To Pdf    ${receipt_html}    ${path_receipt}
    [Return]        ${path_receipt}

*** Keywords ***
Take a screenshot of the robot
    [Arguments]     ${order}
    Set Local Variable    ${OrderNumber}    ${order}[Order number]
    Set Local Variable    ${path_screen}    ${CURDIR}${/}robots${/}OrderNumber_${OrderNumber}.png
    Sleep    3
    Capture Element Screenshot    id:robot-preview-image    ${path_screen}
    [Return]       ${path_screen}

*** Keywords ***
Embed the robot screenshot to the receipt PDF file
    [Arguments]     ${screenshot}   ${pdf}
    Add Watermark Image To Pdf    ${screenshot}     ${pdf}     ${pdf}

*** Keywords ***
Go to order another robot
    Click Button        id:order-another

*** Keywords ***
Create Zip file of the receipts
    Archive Folder With Zip     ${CURDIR}${/}receipts       ${CURDIR}${/}output${/}Archive.zip

*** Keywords ***
Collect order location
    Add heading       Select order.csv file location
    Add text          Only for Dialog demo.     size=Small
    Add text          Please choose https://robotsparebinindustries.com/orders.csv    size=Small
    Add radio buttons
    ...    name=order_location
    ...    options=https://robotsparebinindustries.com/orders.csv,https://URLFORDEMOPORPOSE.com/DEMO.csv
    ...    default=https://robotsparebinindustries.com/orders.csv
    ...    label=URL
    ${result}=    Run dialog        title=Order.csv file location    height=400    width=480
    [Return]    ${result.order_location}

*** Tasks ***
Orders robots from RobotSpareBin Industries Inc.
    Create Zip file of the receipts

*** Tasks ***
Orders robots from RobotSpareBin Industries Inc.
    Open Robot Ordering Website
    ${order_path}=      Collect order location
    Sleep       2
    ${orders}=    Get orders        ${order_path}
    FOR     ${order}        IN      @{orders}
        Close the annoying modal
        Fill Form      ${order}
        Preview the Robot
        Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${order}
        ${screenshot}=    Take a screenshot of the robot    ${order}
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create Zip file of the receipts


