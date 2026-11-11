#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing) Export
	
	InitializeDocument(FillingData);
	
	ARAPAccountingServer.Filling(ThisObject, FillingData);
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	ARAPAccountingServer.BeforeWrite(ThisObject, Cancel, WriteMode);
	
	SelectionOfGiftCertificates_2_5 = SelectionOfGiftCertificates_2_5();
	DocumentAmount = AmountsForGiftCertificates_2_5(SelectionOfGiftCertificates_2_5);
	
	If WriteMode = DocumentWriteMode.Posting Then
		
		FillInCalculationObject(SelectionOfGiftCertificates_2_5);
		
	Else
		
		For Each TSRow In GiftCertificates Do
			TSRow.ARAPObject = Undefined;
		EndDo;
		
	EndIf;
	
	TMCommonUse.FillInDocumentIDs(ThisObject, "GiftCertificates");
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	GiftCertificatesServer.FillCheckProcessing(ThisObject, Cancel);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	InitializeDocument();
	
	GiftCertificates.Clear();
	
	ARAPAccountingServer.OnCopy(ThisObject);
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "GiftCertificates");
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	ChangesTable = VATAccountingERP.NewCalculationChangeTable();
	ChangesRow = ChangesTable.Add();
	ChangesRow.Document = Ref;
	ChangesRow.Period = Date;
	VATAccountingERP.ReflectChangesInSettlementsWithCustomersInVATAccounting(ChangesTable);
	
EndProcedure

#EndRegion

#Region Private

Function SelectionOfGiftCertificates_2_5()
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	GiftCertificates.LineNumber AS LineNumber,
	|	CAST(GiftCertificates.GiftCertificate AS Catalog.GiftCertificates) AS GiftCertificate,
	|	GiftCertificates.AmountInCertificateCurrency AS SumBalance
	|INTO TableGiftCertificates
	|FROM
	|	&GiftCertificates AS GiftCertificates
	|WHERE
	|	GiftCertificates.AmountInCertificateCurrency <> 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GiftCertificates.LineNumber AS LineNumber,
	|	GiftCertificates.GiftCertificate AS GiftCertificate,
	|	ISNULL(ARAPObjects.Ref, VALUE(Catalog.ARAPObjects.EmptyRef)) AS ARAPObject,
	|	GiftCertificates.SumBalance AS SumBalance
	|FROM
	|	TableGiftCertificates AS GiftCertificates
	|		LEFT JOIN Catalog.ARAPObjects AS ARAPObjects
	|		ON GiftCertificates.GiftCertificate = ARAPObjects.Object
	|			AND NOT ARAPObjects.DeletionMark
	|WHERE
	|	GiftCertificates.GiftCertificate.Owner.GiftCardAccounting25";
	Query.SetParameter("GiftCertificates", GiftCertificates.Unload());
	
	Return Query.Execute().Select();
	
EndFunction

#Region InitializationAndFilling

Procedure InitializeDocument(FillingData = Undefined) Export
	
	Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	Manager    = Users.CurrentUser();
	Currency      = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	Author       = Users.CurrentUser();
	
EndProcedure

Procedure FillInCalculationObject(SelectionOfGiftCertificates_2_5)
	
	SelectionOfGiftCertificates_2_5.Reset();
	
	While SelectionOfGiftCertificates_2_5.Next() Do
		IndexOf = SelectionOfGiftCertificates_2_5.LineNumber - 1;
		GiftCertificates[IndexOf].ARAPObject = SelectionOfGiftCertificates_2_5.ARAPObject;
	EndDo;
	
EndProcedure

Function AmountsForGiftCertificates_2_5(SelectionOfGiftCertificates_2_5)
	
	AmountsForGiftCertificates_2_5 = 0;
	SelectionOfGiftCertificates_2_5.Reset();
	While SelectionOfGiftCertificates_2_5.Next() Do
		AmountsForGiftCertificates_2_5 = AmountsForGiftCertificates_2_5 + SelectionOfGiftCertificates_2_5.SumBalance;
	EndDo;
	
	Return AmountsForGiftCertificates_2_5;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
