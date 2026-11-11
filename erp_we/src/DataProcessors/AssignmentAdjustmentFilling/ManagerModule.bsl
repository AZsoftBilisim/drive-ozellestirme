
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Adds an object creation command.
//
// Parameters:
//  GenerationCommands - ValueTable - command table.
// Returns:
//  ValueTableRow, Undefined - description of the added command.
Function AddCreateCommandBasedOnReserveWithdrawal(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.InventoryAssignmentAdjustment) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.DataProcessors.AssignmentAdjustmentFilling.FullName();
		CreateBasedOnCommand.Handler = "GenerationByReferenceTMClient.OpenReserveWithdrawalWizard";
		CreateBasedOnCommand.Presentation = NStr("vi = 'Điều chỉnh điểm đến của hàng hóa (giảm dự phòng)';
												|ru = 'Корректировка назначения товаров (снятие резерва)';
												|en = 'Inventory assignment adjustment (remove from reserve)'; fa = 'Inventory assignment adjustment (remove from reserve)';
												|it = 'Correzione dell''assegnazione della merce (rimuovere dai prodotti riservati)';
												|pl = 'Zapis korygujący przeznaczenia towarów (wycofanie rezerwy)';
												|tr = 'Stok atama düzeltmesi (rezervin kaldırılması)'");
		CreateBasedOnCommand.WriteMode = "Post";
		
		Return CreateBasedOnCommand;
	EndIf;
	
	Return Undefined;
EndFunction

// Adds an object creation command.
//
// Parameters:
//  GenerationCommands - ValueTable - command table.
// Returns:
//  ValueTableRow, Undefined - description of the added command.
Function AddCreateCommandBasedOnReservation(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.InventoryAssignmentAdjustment) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.DataProcessors.AssignmentAdjustmentFilling.FullName();
		CreateBasedOnCommand.Handler = "GenerationByReferenceTMClient.OpenBackupWizard";
		CreateBasedOnCommand.Presentation = NStr("vi = 'Điều chỉnh mục đích hàng hóa (đặt chỗ)';
												|ru = 'Корректировка назначения товаров (резервирование)';
												|en = 'Inventory assignment adjustment (reservation)'; fa = 'Inventory assignment adjustment (reservation)';
												|it = 'Correzione dell''assegnazione della merce (sistema di riserva)';
												|pl = 'Zapis korygujący przeznaczenia towarów (rezerwacja)';
												|tr = 'Stok atama düzeltmesi (rezervasyon)'");
		CreateBasedOnCommand.WriteMode = "Post";
		
		Return CreateBasedOnCommand;
	EndIf;
	
	Return Undefined;
EndFunction

// Constructor of the parameters of the form for filling in the assignment correction.
// Returns:
//  Structure - structure with fields:
//   * Master_2 - Boolean - true, when the form is closed, a document will be created,
//              False - as a result, the goods to be filled in will be placed in temporary storage.
//   * OperationKind - EnumRef.KindsOfAssignmentAdjustmentOperations - type of operation.
//   * Purpose - CatalogRef.Assignments - the purpose for which you need to fill out the document.
//   * OrderDocument - DocumentRef - the order in the context of which the filling is called.
//   * Organization - CatalogRef.BusinessStructure - it is used to select balances for assigning orders to a given organization.
//   * AddressOfGoods - String - the address of the warehouse with the goods selection table.
//   * AssignmentAdjustment - DocumentRef.InventoryAssignmentAdjustment - a link to a refillable document that could have already been held earlier.
//   * Count - Number - used in the counter adjustment operation.
Function FormParameters() Export
	
	FormParameters = New Structure();
	FormParameters.Insert("Master_2",                  False);
	FormParameters.Insert("OperationKind",             Undefined);
	FormParameters.Insert("Purpose",              Undefined);
	FormParameters.Insert("OrderDocument",                   Undefined);
	FormParameters.Insert("Organization",             Undefined);
	FormParameters.Insert("AddressOfGoods",            Undefined);
	FormParameters.Insert("AssignmentAdjustment", Undefined);
	FormParameters.Insert("Count",              Undefined);

	Return FormParameters;
		
EndFunction

#EndRegion

#Region Internal

Function CreateDocumentsInBackground(ProcedureParameters) Export
	
	DocumentsList = New Array();
	
	ItemsToTransfer = ProcedureParameters.ItemsToTransfer;
	TableRow = Undefined;
	NewAssignment = Undefined;
	CurProducts_1 = ItemsToTransfer.CopyColumns();
	Errors = New Array();
	For IndexOf = 0 To ItemsToTransfer.Count() Do
		
		If IndexOf < ItemsToTransfer.Count() Then
			TableRow = ItemsToTransfer[IndexOf];
		EndIf;
		
		If IndexOf = ItemsToTransfer.Count()
			Or TableRow.NewAssignment <> NewAssignment Then
				
				If NewAssignment <> Undefined Then
					
					HeaderAttributes = New Structure("OperationKind,Organization,Purpose");
					FillPropertyValues(HeaderAttributes, ProcedureParameters);
					HeaderAttributes.Purpose = NewAssignment;
					DocumentCreationResult = Documents.InventoryAssignmentAdjustment.CreateFillAndNavigateDocument(
						HeaderAttributes,
						CurProducts_1);
					DocumentsList.Add(DocumentCreationResult.Document);
					If Not DocumentCreationResult.Posted Then
						DocumentErrors = New Structure("Errors,Document");
						FillPropertyValues(DocumentErrors, DocumentCreationResult);
						Errors.Add(DocumentErrors);
					EndIf;
					
				EndIf;
				
				CurProducts_1.Clear();
				If IndexOf < ItemsToTransfer.Count() Then
					NewAssignment = TableRow.NewAssignment;
				EndIf;
				
		EndIf;
		
		FillPropertyValues(CurProducts_1.Add(), TableRow);
		
	EndDo;
	ProvisionInDocumentsServer.CheckToRunBackgroundInventoryAllocationJob();
	Result = New Structure("Documents,Errors", DocumentsList, Errors);
	Return Result;
	
EndFunction

#EndRegion

#EndIf
