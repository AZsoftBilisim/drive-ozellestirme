#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnCopy(CopiedObject)
	
	InitializeDocumentBeforeFillingItOut();
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	InitializeDocumentBeforeFillingItOut();
	
	FillInDataType = TypeOf(FillingData);
	
	If FillInDataType = Type("DocumentRef.PhysicalCountOfInventoryInOperation") Then
		
		FillInBasedOnInventory(FillingData);
		
	EndIf;
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	ProductsServer.ClearUnusedSeries(
		ThisObject,
		ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.TransferInOperation));
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	AttributesNotToCheck = New Array;
	
	CheckingDocumentFilling(AttributesNotToCheck, Cancel);
	CheckingFillingOfOtherSubsystems(AttributesNotToCheck, Cancel);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, AttributesNotToCheck);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
EndProcedure

#EndRegion

#Region Private

Procedure InitializeDocumentBeforeFillingItOut(FillingData = Undefined)
	
	EmployeeResponsible = Users.CurrentUser();
	Organization = SettingsValueCached.GetDefaultOrganization(Organization);

	ObjectsFillingByStatistics.FillObjectAttributes(ThisObject, FillingData);
	
EndProcedure

Procedure CheckingDocumentFilling(AttributesNotToCheck, Cancel)
	
	InventoryInOperationServer.CheckInventoryRecords(ThisObject, AttributesNotToCheck, Cancel);
	
	CheckParameters = InventoryInOperationServer.ParametersForCheckingAccountingForIndividuals();
	CheckParameters.BankingDetailsOfIndividual.Clear();
	CheckParameters.BankingDetailsOfIndividual.Add("Individual", NStr("vi = 'Cá nhân (người gửi)';
																		|ru = 'Физическое лицо (отправитель)';
																		|en = 'Person (sender)'; fa = 'شخص (فرستنده)';
																		|it = 'Persona fisica (mittente)';
																		|pl = 'Osoba fizyczna (nadawca)';
																		|tr = 'Gerçek kişi (gönderen)'"));
	CheckParameters.BankingDetailsOfIndividual.Add("IndividualRecipient", NStr("vi = 'Cá nhân (người nhận)';
																				|ru = 'Физическое лицо (получатель)';
																				|en = 'Person (recipient)'; fa = 'شخص (گیرنده)';
																				|it = 'Persona fisica (destinatario)';
																				|pl = 'Osoba fizyczna (odbiorca)';
																				|tr = 'Gerçek kişi (alan)'"));
	InventoryInOperationServer.CheckAccountingForIndividuals(ThisObject, AttributesNotToCheck, Cancel, CheckParameters);
	
EndProcedure

Procedure CheckingFillingOfOtherSubsystems(AttributesNotToCheck, Cancel)
	
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject, AttributesNotToCheck, Cancel);
	
	ProductsServer.CheckSeriesCompletion(
		ThisObject,
		ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.TransferInOperation),
		Cancel,
		AttributesNotToCheck);
	
EndProcedure

Procedure FillInBasedOnInventory(Val FillingData)
	
	If TypeOf(FillingData) = Type("Structure") Then
		DocumentBasis = FillingData.DocumentBasis;
	Else
		DocumentBasis = FillingData;
	EndIf;
	
EndProcedure

#EndRegion

#EndIf