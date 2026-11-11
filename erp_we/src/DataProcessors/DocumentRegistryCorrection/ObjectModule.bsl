#If Server Or ThickClientOrdinaryApplication Then

#Region Public

// Clears the document Registry information register of broken links.
//
// Parameters:
//	ExecutionParameters - Structure - background task execution parameters.
//	ResultAddress - String - the address of the task execution result in the temporary storage.
//
Procedure ClearNonExistentLinksInDocumentRegistryInBackground(ExecutionParameters, ResultAddress) Export
	
	ExecutionResult = DataProcessors.DocumentRegistryCorrection.ClearNonexistentLinksInDocumentRegistry();
	
	PutToTempStorage(ExecutionResult, ResultAddress);
	
EndProcedure

// Performs the re-reflection of documents in the information register "Document Register".
//
// Parameters:
//	ExecutionParameters - Structure - background task execution parameters.
//	ResultAddress - String - the address of the task execution result in the temporary storage.
//
Procedure RedefineDocumentsInDocumentRegistry(ExecutionParameters, ResultAddress) Export
	
	TypesOfDocumentRegistry = InformationRegisters.DocumentsRegistry.TypesOfRegistryDocuments();

	DocumentsToBeReflectedInRegister = New Map;

	For Each DocumentType In TypesOfDocumentRegistry Do
		MetadataOfDocument = Metadata.FindByType(DocumentType);
		DocumentsToBeReflectedInRegister.Insert(MetadataOfDocument);
	EndDo;
	
	If DocumentsToBeReflectedInRegister.Count() > 0 Then
		InformationRegisters.DocumentsRegistry.ReflectDocumentDataInRegistry(DocumentsToBeReflectedInRegister);
	EndIf;
	
EndProcedure

#EndRegion

#EndIf