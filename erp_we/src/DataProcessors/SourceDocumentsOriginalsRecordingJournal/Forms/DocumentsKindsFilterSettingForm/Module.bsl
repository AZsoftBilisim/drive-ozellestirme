///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2021, 1C-Soft LLC
// All rights reserved. This program and accompanying materials are provided 
// in accordance with the terms of the Attribution 4.0 International (CC BY 4.0) license
// The license text is available at the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	FillInDocumentViewSelectionList();

	If Parameters.Property("FilterDocumentsKinds") Then
		
		If Parameters.FilterDocumentsKinds.Count() > 0 Then

			For Each DocumentKind In DocumentsKindsTable Do
				DocumentKind.Filter = False;
			EndDo;

			For Each DocumentKind In Parameters.FilterDocumentsKinds Do
				Filter = New Structure("DocumentKind",DocumentKind.Value);
				FoundRows = DocumentsKindsTable.FindRows(Filter);
				If ValueIsFilled(FoundRows) Then
					For Each String In FoundRows Do
						String.Filter = True;
					EndDo;
				EndIf;
			EndDo;
		EndIf;
	Else
			
		For Each DocumentKind In DocumentsKindsTable Do
			DocumentKind.Filter = True;
		EndDo;		
	EndIf;

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure WillSelectAllCheckBoxes(Command)

	For Each CurrentFilter In DocumentsKindsTable Do
		CurrentFilter.Filter = True;
	EndDo;

EndProcedure

&AtClient
Procedure ClearAllCheckBoxes(Command)

	For Each CurrentFilter In DocumentsKindsTable Do
		CurrentFilter.Filter = False;
	EndDo;

EndProcedure

&AtClient
Procedure AllTypesOfDocumentsOK(Command)

	FillInListOfDocumentsByDocumentType();
	Result = New Structure("FilterDocumentsKinds,DocumentsCount",FilterDocumentsKinds,DocumentsKindsTable.Count());
	Close(Result);

EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure FillInDocumentViewSelectionList()

	TableOfSpecies = FormAttributeToValue("DocumentsKindsTable");
	TableOfSpecies.Clear();

	AvailableTypes = DataProcessors.SourceDocumentsOriginalsRecordingJournal.ObjectsWithSourceDocumentsOriginalsAccounting();
	DocumentNames = New Array;
	For Each Type In AvailableTypes.Types() Do
		DocumentType = Metadata.FindByType(Type);
		DocumentNames.Add(DocumentType.FullName());
	EndDo;
	
	Query = New Query;
	Query.Text = "SELECT
	               |	MetadataObjectIDs.FullName AS FullName,
	               |	MetadataObjectIDs.Synonym AS Synonym,
	               |	MetadataObjectIDs.Ref AS Ref
	               |FROM
	               |	Catalog.MetadataObjectIDs AS MetadataObjectIDs
	               |WHERE
	               |	MetadataObjectIDs.FullName IN(&DocumentNames)";
	Query.SetParameter("DocumentNames",DocumentNames);
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		Filter = New Structure("Presentation", Selection.Synonym);
		FoundRows = TableOfSpecies.FindRows(Filter);
		If FoundRows.Count()= 0 Then
			NewRow = TableOfSpecies.Add();
			NewRow.DocumentKind = Selection.Ref;
			NewRow.Presentation = Selection.Synonym;
			NewRow.Filter = True;
		EndIf;
	EndDo;
	
	//checking the FO of sales
	If Not GetFunctionalOption("UseTransferToCustodyWithRightOfSale")
		And Not GetFunctionalOption("UseProductionByThirdParty2_5")
		And Not GetFunctionalOption("UseCustodyDuringPurchase") Then
		LinesToDelete = TableOfSpecies.FindRows(New Structure("DocumentKind",																	
			Catalogs.MetadataObjectIDs.FindByAttribute("Name", "TransferOfGoodsToBailee")));
																
		For Each RowToDelete In LinesToDelete Do
			TableOfSpecies.Delete(RowToDelete);
		EndDo;
		
		LinesToDelete = TableOfSpecies.FindRows(New Structure("DocumentKind",																	
			Catalogs.MetadataObjectIDs.FindByAttribute("Name", "RedemptionOfGoodsFromStorage")));
																
		For Each RowToDelete In LinesToDelete Do
			TableOfSpecies.Delete(RowToDelete);
		EndDo;

	EndIf;
	
	If Not GetFunctionalOption("UseCreditNotes") Then
		LinesToDelete = TableOfSpecies.FindRows(New Structure("DocumentKind",																	
			Catalogs.MetadataObjectIDs.FindByAttribute("Name", "SaleAdjustment")));
																
		For Each RowToDelete In LinesToDelete Do
			TableOfSpecies.Delete(RowToDelete);
		EndDo;
	EndIf;
	
	If Not GetFunctionalOption("UseReportsOfDiscrepanciesAfterShipment") Then
		LinesToDelete = TableOfSpecies.FindRows(New Structure("DocumentKind",																	
			Catalogs.MetadataObjectIDs.FindByAttribute("Name", "DiscrepancyReportFollowingShipment")));
																
		For Each RowToDelete In LinesToDelete Do
			TableOfSpecies.Delete(RowToDelete);
		EndDo;
	EndIf;

	//FO of production

	
	If Not GetFunctionalOption("UseTollManufacturing2_5") Then
		
		LinesToDelete = DocumentsKindsTable.FindRows(
			New Structure(
				"DocumentKind",
				Catalogs.MetadataObjectIDs.FindByAttribute("Name", "ReportToMaterialProvider2_5")));
		
		For Each RowToDelete In LinesToDelete Do
			DocumentsKindsTable.Delete(RowToDelete);
		EndDo;
		
	EndIf;

	//
	//Purchasing information
	If Not GetFunctionalOption("UseDebitNotes") Then
		LinesToDelete = TableOfSpecies.FindRows(New Structure("DocumentKind",																	
			Catalogs.MetadataObjectIDs.FindByAttribute("Name", "PurchaseAdjustment")));
																
		For Each RowToDelete In LinesToDelete Do
			TableOfSpecies.Delete(RowToDelete);
		EndDo;
	EndIf;
	
	If Not GetFunctionalOption("UseNonConformanceCertificatesFollowingAcceptance") Then
		LinesToDelete = TableOfSpecies.FindRows(New Structure("DocumentKind",																	
			Catalogs.MetadataObjectIDs.FindByAttribute("Name", "DiscrepancyReportFollowingReceipt")));
																
		For Each RowToDelete In LinesToDelete Do
			TableOfSpecies.Delete(RowToDelete);
		EndDo;
	EndIf;
	
	//FO of internal documents
	If Not GetFunctionalOption("UseGoodsTransfer") Then
		LinesToDelete = TableOfSpecies.FindRows(New Structure("DocumentKind",																	
			Catalogs.MetadataObjectIDs.FindByAttribute("Name", "InventoryTransfer")));
																
		For Each RowToDelete In LinesToDelete Do
			TableOfSpecies.Delete(RowToDelete);
		EndDo;
	EndIf;
	
	If Not GetFunctionalOption("UseNonConformanceCertificatesFollowingTransfer") Then
		LinesToDelete = TableOfSpecies.FindRows(New Structure("DocumentKind",																	
			Catalogs.MetadataObjectIDs.FindByAttribute("Name", "DiscrepancyReportFollowingTransfer")));
																
		For Each RowToDelete In LinesToDelete Do
			TableOfSpecies.Delete(RowToDelete);
		EndDo;
	EndIf;
	
	
	//FO documents between organizations
	If Not GetFunctionalOption("UseCustomerInvoiceIntercompany") Then
		LinesToDelete = TableOfSpecies.FindRows(New Structure("DocumentKind",																	
			Catalogs.MetadataObjectIDs.FindByAttribute("Name", "IntercompanyGoodsReturn")));
																
		For Each RowToDelete In LinesToDelete Do
			TableOfSpecies.Delete(RowToDelete);
		EndDo;
		
		LinesToDelete = TableOfSpecies.FindRows(New Structure("DocumentKind",																	
			Catalogs.MetadataObjectIDs.FindByAttribute("Name", "CommissionReportIntercompany")));
																
		For Each RowToDelete In LinesToDelete Do
			TableOfSpecies.Delete(RowToDelete);
		EndDo;
		
		LinesToDelete = TableOfSpecies.FindRows(New Structure("DocumentKind",																	
			Catalogs.MetadataObjectIDs.FindByAttribute("Name", "CustomerInvoiceIntercompany")));
																
		For Each RowToDelete In LinesToDelete Do
			TableOfSpecies.Delete(RowToDelete);
		EndDo;
	EndIf;
	
	TableOfSpecies.Sort("Presentation");
	ValueToFormAttribute(TableOfSpecies, "DocumentsKindsTable");
	
EndProcedure

&AtServer
Procedure FillInListOfDocumentsByDocumentType()

	FilterDocumentsKinds.Clear();
	
	For Each DocumentKind In DocumentsKindsTable Do
			If DocumentKind.Filter = True Then
				FilterDocumentsKinds.Add(DocumentKind.DocumentKind,DocumentKind.Presentation);
			EndIf;
	EndDo;

	If FilterDocumentsKinds.Count() = 0 Then
		For Each DocumentKind In DocumentsKindsTable Do
			FilterDocumentsKinds.Add(DocumentKind.DocumentKind,DocumentKind.Presentation);
		EndDo;
	EndIf;

EndProcedure

#EndRegion
