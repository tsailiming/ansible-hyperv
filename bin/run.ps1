#!/usr/bin/env pwsh

$hostname=""
$user = "admin"
$pass= "system"

function Launch-JobTemplate([string]$env) {
 
  $url="https://$hostname/api/v2/job_templates/$template_id/launch/"

  $pair = "$($user):$($pass)"
  $encodedCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($pair))
  $basicAuthValue = "Basic $encodedCreds"
  $headers = @{ Authorization = $basicAuthValue }

  $extra_vars = @{
    extra_vars = (ConvertTo-Json(@{env=$env}))
  }

  $responseData = Invoke-WebRequest -Uri $url -Method Post -Headers $headers -Body (ConvertTo-Json $extra_vars) -ContentType "application/json" -SkipCertificateCheck #-UseBasicParsing
  $data =  $responseData | ConvertFrom-Json

  $job_url = $data.url
  $poll_url = "https://$hostname$job_url"
  $status = $data.status
  $name = $data.name
  Write-Host "JOB NAME=$name JOB URL=$poll_url"
  
  # new: New
  # pending: Pending
  # waiting: Waiting
  # running: Running
  # successful: Successful
  # failed: Failed
  # error: Error
  # canceled: Canceled

  $exit_states = "new", "pending", "waiting", "running"

  while ($exit_states -contains $status) {
    $responseData = Invoke-WebRequest -Uri $poll_url -Method Get -Headers $headers -SkipCertificateCheck #-UseBasicParsing
    $status = ($responseData | ConvertFrom-Json).status
    Write-Host "Job Status = $status"
    Start-Sleep -s 1
  }
}

$template_id = Read-Host -Prompt 'Enter template id (7=create_vm, 9=prov_web_db, 10=win_ping)'
Launch-JobTemplate -env "test"

