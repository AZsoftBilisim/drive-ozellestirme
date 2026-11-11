#Region Private

// The function returns the name of the register in which you want to reflect the document.
//
// Parameters:
//  MetadataObjectName3 - String - name of the document metadata object.
//  
// Returns:
//  String - the name of the information register in which you want to reflect the document.
//
Function NameOfRegisterToReflectDocument(MetadataObjectName3) Export

	ConformityOfMeasurements = ComplianceOfMeasurementsOfRegistersOfStatesOfDocuments();
	RegisterName = "";
	
	For Each MapItem In ConformityOfMeasurements Do
	
		MetadataObject = MapItem.Key.Dimensions.Find(MapItem.Value);
		
		If MetadataObject <> Undefined Then
		
			ValueTypes = MetadataObject.Type.Types();
			
			For Each TypeOfMeasurementValue In ValueTypes Do
				
				DocumentRef = New(TypeOfMeasurementValue);
				MetadataObject = DocumentRef.Metadata();
				If MetadataObject.Name = MetadataObjectName3 Then
				
					RegisterName = MapItem.Key.Name;
				
				EndIf;
			
			EndDo;
		
		EndIf;
	
	EndDo;
	
	Return RegisterName;

EndFunction

// The function determines the need to reflect the document in the document State registers in the current session.
//
// Parameters:
//  DocumentSourceName - String - name of the document metadata object.
//  
// Returns:
//  Boolean - indicates whether it is reflected in the current session.
//
Function PerformReflectionInCurrentSession(DocumentSourceName) Export

	TypesOfReflectionExecutionDocumentsInCurrentSession = TypesOfDocumentsForCalculatingStatusInTransaction();
	PerformReflectionInCurrentSession = TypesOfReflectionExecutionDocumentsInCurrentSession.Find(DocumentSourceName) <> Undefined;
	Return PerformReflectionInCurrentSession;

EndFunction

// The function returns the names of the document data types that need to be reflected in the current session.
// 
// Returns:
//  Array of String - array of document names.
//
Function TypesOfDocumentsForCalculatingStatusInTransaction() Export

	ConformityOfMeasurements = ComplianceOfMeasurementsOfRegistersOfStatesOfDocuments();
	DocumentTypes = New Array;
	
	For Each MapItem In ConformityOfMeasurements Do
	
		MetadataObject = MapItem.Key.Dimensions.Find(MapItem.Value);
		
		If MetadataObject <> Undefined Then
		
			ValueTypes = MetadataObject.Type.Types();
			
			For Each TypeOfMeasurementValue In ValueTypes Do
				
				DocumentRef = New(TypeOfMeasurementValue);
				MetadataObject = DocumentRef.Metadata();
				
				If DocumentTypes.Find(MetadataObject.Name) = Undefined Then
				
					DocumentTypes.Add(MetadataObject.Name);
				
				EndIf;	
			
			EndDo;
		
		EndIf;
	
	EndDo;
	
	Return DocumentTypes;

EndFunction

// The function returns the names of the document data types that need to be reflected in the current session.
// 
// Returns:
// 	Map of KeyAndValue - Contains the texts of the cancellation requests, where:
// 		* Key - MetadataObjectInformationRegister - names of document reflection registers.
// 		* Value - String - the name of the dimension with the types of documents reflected in it.
//
Function ComplianceOfMeasurementsOfRegistersOfStatesOfDocuments() Export
	
	MetadataOfInformationRegisters = Metadata.InformationRegisters;
	
	ConformityOfMeasurements = New Map;
	ConformityOfMeasurements.Insert(MetadataOfInformationRegisters.SalesOrderStates, "OrderDocument");
	ConformityOfMeasurements.Insert(MetadataOfInformationRegisters.PurchaseOrderStates, "OrderDocument");
	ConformityOfMeasurements.Insert(MetadataOfInformationRegisters.StatusesOfInternalOrders, "OrderDocument");
	ConformityOfMeasurements.Insert(MetadataOfInformationRegisters.ProductionStageStates, "Stage");
	ConformityOfMeasurements.Insert(MetadataOfInformationRegisters.StatesOfProductionOrders, "OrderDocument");
	Return ConformityOfMeasurements;

EndFunction

#EndRegion
