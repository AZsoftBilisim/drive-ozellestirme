////////////////////////////////////////////////////////////////////////////////
// General procedures and functions for working with uploading and uploading from Excel
//  
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Function-Create an attached excel file
//
// Parameters:
//  DocumentRef		 - DocumentRef.PurchasePlan - a link to the document for which the attached file is being created.
//  					 - DocumentRef.SalesPlan - a link to the document for which the attached file is being created.
//  					 - DocumentRef.PlanOfGoodsStock - a link to the document for which the attached file is being created.
//  					 - DocumentRef.SalesPlanByCategories - a link to the document for which the attached file is being created.
//  					 - DocumentRef.ProductionPlan - a link to the document for which the attached file is being created.
//  					 - DocumentRef.AssemblyDisassemblyPlan - a link to the document for which the attached file is being created.
//  					 - DocumentRef.InventoryConsumptionPlan - a link to the document for which the attached file is being created.
//  FormIdentifier	 - UUID	 - the ID of the form.
// 
// Returns:
//  Structure - Parameters of the created attached file.
Function CreateAttachedExcelFile(DocumentRef, FormIdentifier) Export 
	
	Manager = Common.ObjectManagerByRef(DocumentRef);
	
	Try
		Return Manager.CreateAttachedExcelFile(DocumentRef, FormIdentifier);
	Except
		Return Undefined;
	EndTry; 
	
EndFunction 

#EndRegion