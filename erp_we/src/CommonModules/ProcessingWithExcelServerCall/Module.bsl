////////////////////////////////////////////////////////////////////////////////
// General procedures and functions for working with uploading and uploading from Excel
//  
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Creating an attached file with Excel
// Details See ProcessingWithExcel.CreateAttachedExcelFile.
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

	Return ProcessingWithExcel.CreateAttachedExcelFile(DocumentRef, FormIdentifier);

EndFunction 

#EndRegion

#Region Internal

// See FilesOperations.FileData
//
Function GetFileData(Val AttachedFile, Val AdditionalParameters = Undefined) Export
	Return FilesOperations.FileData(AttachedFile, AdditionalParameters);
EndFunction

#EndRegion