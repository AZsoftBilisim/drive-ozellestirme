
#Region Private

Function AssortmentVerificationParameters() Export 
	
	AssortmentInspectionStructure = New Structure;
	
	AssortmentInspectionStructure.Insert("Warehouse", 				  Undefined);
	AssortmentInspectionStructure.Insert("Date", 					  Undefined);
	AssortmentInspectionStructure.Insert("MessageText", 		  Undefined);
	AssortmentInspectionStructure.Insert("NameOfAssortmentResource",  Undefined);
	AssortmentInspectionStructure.Insert("Ref", 				  Undefined);
	AssortmentInspectionStructure.Insert("AllowAdding", 	  Undefined);
	AssortmentInspectionStructure.Insert("CheckedYouCanAdd", Undefined);
	
	Return AssortmentInspectionStructure;
	
EndFunction

#EndRegion
