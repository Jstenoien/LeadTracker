add-type -name win -member '[DllImport("user32.dll")] public static extern bool ShowWindow(int handle, int state);' -namespace native
[native.win]::ShowWindow(([System.Diagnostics.Process]::GetCurrentProcess() | Get-Process).MainWindowHandle, 0)

Add-Type -AssemblyName PresentationFramework

#WPF XAML
[XML]$form = @"
<Window
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Topmost="True" WindowStyle="None" ResizeMode="NoResize" Background="Black" Title="Lead Tracker" Height="90" Width="155" AllowsTransparency="True">
    <Window.Clip>
            <RectangleGeometry Rect="0,0,155,90" RadiusX="8" RadiusY="8"/>
    </Window.Clip>
    <Border BorderBrush="White" BorderThickness="1" CornerRadius="8">
    <Grid>
        <Grid.ColumnDefinitions>
            <ColumnDefinition/>
            <ColumnDefinition Width="0.9*"/>
            <ColumnDefinition Width="1.5*"/>
        </Grid.ColumnDefinitions>
        <Grid.RowDefinitions>
            <RowDefinition/>
            <RowDefinition/>
            <RowDefinition Height="1.75*"></RowDefinition>
        </Grid.RowDefinitions>
        <Label Foreground="White" HorizontalAlignment="Right" VerticalAlignment="Center" Margin="0" FontWeight="Bold" Grid.Row="0" Grid.Column="0" Content="Shift:"/>
        <TextBox Name="TimeBox" VerticalContentAlignment="Center" HorizontalContentAlignment="Center" Grid.Row="0" Grid.Column="1"/>
        <Button Name="CallBtn" HorizontalContentAlignment="Center" Grid.Row="0" Grid.RowSpan="2" Grid.Column="2">
            <Button.Resources>
                <Style TargetType="Border">
                    <Setter Property="CornerRadius" Value="0,8,0,0"/>
                </Style>
            </Button.Resources>
            <TextBlock TextAlignment="Center" TextWrapping="Wrap">Lead Completed</TextBlock>
        </Button>
        <Label Foreground="White" Margin="0" HorizontalAlignment="Right" VerticalAlignment="Center" FontWeight="Bold" Grid.Row="1" Grid.Column="0" Content="Leads:"/>
        <TextBox Name="CallBox" VerticalContentAlignment="Center" Padding="5,0,0,0" Grid.Row="1" Grid.Column="1"/>
        <Label Foreground="White" FontSize="20" HorizontalAlignment="Center" VerticalAlignment="Center" FontWeight="Bold" Name="StatLabel" Grid.Row="2" Grid.Column="0" Grid.ColumnSpan="3" Content="">
            <Label.ToolTip>
                   <ToolTip Name="StatsTT"/> 
            </Label.ToolTip> 
        </Label>
        <Button Name="X" HorizontalAlignment="Right" VerticalAlignment="Top" VerticalContentAlignment="Center" Height="10" Width="20" Content="X" Foreground="White" Background="Red" Grid.Row="0" Grid.Column="2" FontSize="6">
            <Button.Resources>
                <Style TargetType="Border">
                    <Setter Property="CornerRadius" Value="0,8,0,4"/>
                </Style>
            </Button.Resources>
        </Button>
    </Grid>
    </Border>
</Window>
"@

#Calculate Leads/Hr
function stats($Time,$Leads){
    #Split HH:MM string to array
    $TimeArr = $Time.split(":")
    #Convert to decimal hours
    $Hours = ([int]::parse($TimeArr[0]))+(([int]::parse($TimeArr[1]))/60)
    #Deal with edge case/first startup
    if($Hours -eq 0 -or $Leads -eq "0"){
        $stats = "0 Leads/Hr"
    } else {
        #Round 
        $stats = [string]([math]::round((([int]::parse($Leads))/$Hours),2)) + " Leads/Hr"
    }
    return $stats
}

function TTupdate($Time,$Leads){
    #Split HH:MM string to array
    $TimeArr = $Time.split(":")
    #Convert to decimal hours
    $Hours = ([int]::parse($TimeArr[0]))+(([int]::parse($TimeArr[1]))/60)
    $4hrleft = "4 Leads/Hr - " + [string]([math]::Ceiling((($Hours * 4)-$Leads))) + " more.`n"
    $5hrleft = "5 Leads/Hr - " + [string]([math]::Ceiling((($Hours * 5)-$Leads))) + " more.`n"
    $6hrleft = "6 Leads/Hr - " + [string]([math]::Ceiling((($Hours * 6)-$Leads))) + " more.`n"
    $7hrleft = "7 Leads/Hr - " + [string]([math]::Ceiling((($Hours * 7)-$Leads))) + " more.`n"
    $8hrleft = "8 Leads/Hr - " + [string]([math]::Ceiling((($Hours * 8)-$Leads))) + " more."
    $TTString = $4hrleft + $5hrleft + $6hrleft + $7hrleft + $8hrleft
    return $TTString
}

$NR = (New-Object System.Xml.XmlNodeReader $form)
$window = [Windows.Markup.XamlReader]::Load($NR)

$window.Add_MouseLeftButtonDown({
    $window.DragMove()
})

$TimeBox = $window.Findname("TimeBox")
$CallBox = $window.FindName("CallBox")

$StatLabel = $window.FindName("StatLabel")

$CallBtn = $window.FindName("CallBtn")
$XBtn = $window.FindName("X")

$StatsTT = $window.FindName("StatsTT")

$TimeBox.Text = "08:00"
$CallBox.Text = 0
$StatLabel.Content = stats $TimeBox.Text $CallBox.Text
$StatsTT.Content = TTupdate $TimeBox.Text $CallBox.Text

$TimeBox.add_KeyUp({
    if($_.Key -eq "Enter"){
        $StatLabel.Content = stats $TimeBox.Text $CallBox.Text
        $StatsTT.Content = TTupdate $TimeBox.Text $CallBox.Text
    }
})

$CallBox.add_KeyUp({
    $StatLabel.Content = stats $TimeBox.Text $CallBox.Text
    $StatsTT.Content = TTupdate $TimeBox.Text $CallBox.Text
})

$CallBtn.add_click({
    if($CallBox.Text -eq ""){
        $CallBox.Text = 0
    }
    $CallBox.Text=([int]::parse($CallBox.Text))+1
    $StatLabel.Content = stats $TimeBox.Text $CallBox.Text
    $StatsTT.Content = TTupdate $TimeBox.Text $CallBox.Text
})

$XBtn.add_click({
    $window.close()
})

$window.ShowDialog()
