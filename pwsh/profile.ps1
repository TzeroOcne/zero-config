$ESC=[char]27

$env:PATH += ";$env:LOCALAPPDATA\Microsoft\WinGet\Links"
$env:PATH += ";$env:LOCALAPPDATA\Programs\oh-my-posh\bin"

function default-prompt
{
  "PS $($executionContext.SessionState.Path.CurrentLocation)$('>' * ($nestedPromptLevel + 1)) "
  # .Link
  # https://go.microsoft.com/fwlink/?LinkID=225750
  # .ExternalHelp System.Management.Automation.dll-help.xml
}

function prompt
{
  $IN_GIT=$(git rev-parse --is-inside-work-tree)
  $GIT_BRANCH=""
  if ($IN_GIT)
  {
    $GIT_BRANCH="($ESC[92m$((git branch --show-current).TrimStart("* "))$ESC[0m)"
  }
  "$env:CONDA_PROMPT_MODIFIER
PS $ESC[96m$($executionContext.SessionState.Path.CurrentLocation)$ESC[0m $GIT_BRANCH
> "
}

function inkscape {
    & "C:\Program Files\Inkscape\bin\inkscape.com" @args
}

$ColorScheme = @{
  Operator = $PSStyle.Foreground.FromRgb(0xdfdf6f)
  Parameter = $PSStyle.Foreground.FromRgb(0xffff8f)
}

Set-PSReadLineOption -Colors $ColorScheme

Import-Module posh-git
Import-Module PSFzf
Import-Module "$env:ChocolateyInstall\helpers\chocolateyInstaller.psm1" -Force

# https://dev.to/ofhouse/add-a-bash-like-autocomplete-to-your-powershell-4257
# Shows navigable menu of all options when hitting Tab
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete

# Autocompletion for arrow keys
Set-PSReadlineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadlineKeyHandler -Key DownArrow -Function HistorySearchForward

Set-PsFzfOption -TabExpansion

# replace 'Ctrl+t' and 'Ctrl+r' with your preferred bindings:
Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'

oh-my-posh init pwsh --config "$HOME\.config\oh-my-posh\starter.omp.json"|Invoke-Expression
Invoke-Expression (& { (zoxide init powershell --cmd cd| Out-String) })
