Configuration TechMentor2018Config {

    Param()

    Import-DscResource -ModuleName 'LWINConfigs' -ModuleVersion '1.0.0.0'
    
    Node $AllNodes.NodeName
    {
        LWINBaseConfig BaseConfig{



        }
       
    }

    Node ($AllNodes.Where{$_.Role -eq "DSCTarget"}).NodeName
    {
            
                
    }

}
