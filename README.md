# PullDpSetupScript
Powershell script to automate the setup of new pull distribution points in SCCM.
5-26-23
#Requirements:
1. Setting variables to work with your environment. These are located near the top of the script function.
  #This is the SCCM workstation Authorization certificate with private key. 
  -$certPath = "\\Server\drive$\path\to\cert.pfx"
  #your password for said certificate
  -$password = "certPass01"
  #Local domain
  -$domain = "site.example"
  #SCCM site code
  -$siteCode = "SM1"
  #location you would like to keep the failure logs to review after running the script.
  -$logPath = "C:\temp\Setup-DistributionPoints.log"
  #if you have multiple DP groups you can add variables OR use the dpGroupID varient of this (sometimes I have better luck using the IDs).
  -$dpGroupName = "Pull Distribution Points"

2. Creating your CSV of new pull distribution points to set-up:
  #Note here I am using the boundary group name as the description!
  -Make a new note pad paste the following:

  "Device","Description"
  "MyNewDP01","Boundary_Group_Name1"
  "MyNewDP02","Boundary_Group_Name2"

  Re-enter with your device names and corresponding boundary group names.
  #This works really well if you are working from a spreadsheet of new servers and their location.

3. Connect to your site using the SCCM connect to site script.
  (clicking the blue box in the top left of the SCCM console and selecting "Connect via Windows Powershell ISE" will generate the script for your site.)
  Run this script in PowerShell ISE as ADMIN.

4. Call your CSV path with the function call listed at the bottom of the script 
      Set-DistributionPoints -csvPath "\\path\to\file.csv"
      
5. Run this script while connected to the SCCM site with your populated variables and CSV file. 
