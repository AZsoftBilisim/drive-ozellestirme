
#Region Public

// list of available cost group fields.
//	Returns:
//		String - list of available cost group fields.
//
Function CostGroupFields() Export
	
	Return
	"GroupCosts, Document, ExpenseGroup, Products,
	|Characteristic, Purpose, Series, BillOfMaterials";
	
EndFunction

#EndRegion
