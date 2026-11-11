#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	PhysicalCountReportLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	PhysicalCountReportLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	If TypeOf(FillingData) = Type("Structure") Then
		FillPropertyValues(ThisObject, FillingData);
	EndIf;
	
	InitializeDocument();
	
	PhysicalCountReportLocalization.Filling(ThisObject, FillingData, StandardProcessing);

EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	PhysicalCountReportLocalization.Posting(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

Procedure InitializeDocument()

	Date		= CurrentSessionDate();
	
	Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	Warehouse		= SettingsValueCached.GetDefaultWarehouse(Warehouse);
	
	EmployeeResponsible = Users.CurrentUser();
	Department = SettingsValueCached.UserDivision(EmployeeResponsible, Department);
	
	SourseOfInformationAboutPricesForPrinting = Common.ObjectAttributeValue(Warehouse, "SourseOfInformationAboutPricesForPrinting");
	If Not ValueIsFilled(SourseOfInformationAboutPricesForPrinting) And Not GetFunctionalOption("UseSeveralPriceTypes") Then
		SourseOfInformationAboutPricesForPrinting = Enums.SourcesOfPriceInformationForPrinting.ByCost;
	EndIf;
	If SourseOfInformationAboutPricesForPrinting = Enums.SourcesOfPriceInformationForPrinting.ByCost Then
		PriceKind = Undefined;
	Else
		PriceKind = Catalogs.Warehouses.AccountingPriceType(Warehouse);
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
