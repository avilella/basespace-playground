function launchSpec(dataProvider)
{
    return [
        {
            commandLine: ["/usr/bin/perl /home/apps/sickle/sickle_pe.pl -exe /home/apps/sickle/sickle -AccessToken $AccessToken -AppSessionId $AppSessionId -ApiUrl $ApiUrl"],
            containerImageId:"avilella/sickle"
        }
    ];
}
