#Region Private

// See CompaniesLocalization.CheckpointOnDate
Function CheckpointOnDate(Organization, DateOfLastEdit) Export          
	
	Return CompaniesLocalization.CheckpointOnDate(Organization, DateOfLastEdit);
	
EndFunction

Function LargestTaxpayerOfCheckpointOnDate(Organization, DateOfLastEdit) Export          
	
	AttributesOfLargestTaxpayer = CompaniesLocalization.LargestTaxpayerValuesOfAttributesAsOfDate(Organization, DateOfLastEdit);
	
	Return AttributesOfLargestTaxpayer.MajorTaxpayerKPP;
	
EndFunction

#EndRegion