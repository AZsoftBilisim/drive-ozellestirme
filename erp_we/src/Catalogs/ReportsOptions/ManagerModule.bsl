///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#If Not MobileStandaloneServer Then

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region InterfaceImplementation

// StandardSubsystems.BatchEditObjects

// Returns object attributes that can be edited using the bulk attribute modification data processor.
// 
//
// Returns:
//  Array of String
//
Function AttributesToEditInBatchProcessing() Export

	Result = New Array;
	Result.Add("LongDesc");
	Result.Add("Author");
	Result.Add("AuthorOnly");

	Return Result;

EndFunction

// End StandardSubsystems.BatchEditObjects

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowRead
	|WHERE
	|	Custom = FALSE
	|	OR AuthorOnly = FALSE
	|	OR IsAuthorizedUser(Author)
	|;
	|AllowUpdateIfReadingAllowed
	|WHERE
	|	IsAuthorizedUser(Author)";

	Restriction.TextForExternalUsers1 = Restriction.Text;

EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#EndIf

#Region EventHandlers

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

Procedure FormGetProcessing(FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing)
	// Override for Favorites: It will open the main report form (instead of the card with report location settings).
	// 
	If FormType = "ObjectForm" Then
		OptionRef1 = CommonClientServer.StructureProperty(Parameters, "Key");
		If Not ValueIsFilled(OptionRef1) Then
			Raise NStr("vi = 'Chỉ có thể tạo phương án báo cáo mới từ biểu mẫu báo cáo';
						|ru = 'Новый вариант отчета можно создать только из формы отчета';
						|en = 'You can create a report option only from a report form.'; fa = 'You can create a report option only from a report form.';
						|it = 'Una nuova versione del report può essere creata solo dal modulo del rapporto';
						|pl = 'Nowy wariant raportu można utworzyć tylko z formularza raportu';
						|tr = 'Rapor seçeneği yalnızca rapor formunda oluşturulabilir'");
		EndIf;

		OpeningParameters = ReportsOptions.OpeningParameters(OptionRef1);

		ReportsOptionsClientServer.AddKeyToStructure(OpeningParameters, "RunMeasurements", False);

		If OpeningParameters.ReportType = "BuiltIn" Or OpeningParameters.ReportType = "Extension" Then
			Kind = "Report";
		ElsIf OpeningParameters.ReportType = "Additional" Then
			Kind = "ExternalReport";
			If Not OpeningParameters.Property("Connected") Then
				ReportsOptions.OnAttachReport(OpeningParameters);
			EndIf;
			If Not OpeningParameters.Connected Then
				Raise NStr("vi = 'Chỉ có thể mở phương án báo cáo ngoài từ biểu mẫu báo cáo.';
							|ru = 'Вариант внешнего отчета можно открыть только из формы отчета.';
							|en = 'You can open an external report option only from a report form.'; fa = 'You can open an external report option only from a report form.';
							|it = 'La variante del report esterno può essere aperta solo dal modulo del rapporto.';
							|pl = 'Wariant raportu zewnętrznego można otworzyć tylko z formularza raportu.';
							|tr = 'Harici rapor seçeneği sadece rapor formundan açılabilir.'");
			EndIf;
		Else
			Raise NStr("vi = 'Chỉ có thể mở phương án báo cáo ngoài từ biểu mẫu báo cáo.';
						|ru = 'Вариант внешнего отчета можно открыть только из формы отчета.';
						|en = 'You can open an external report option only from a report form.'; fa = 'You can open an external report option only from a report form.';
						|it = 'La variante del report esterno può essere aperta solo dal modulo del rapporto.';
						|pl = 'Wariant raportu zewnętrznego można otworzyć tylko z formularza raportu.';
						|tr = 'Harici rapor seçeneği sadece rapor formundan açılabilir.'");
		EndIf;

		FullReportName = Kind + "." + OpeningParameters.ReportName;

		UniqueKey = ReportsClientServer.UniqueKey(FullReportName, OpeningParameters.VariantKey);
		OpeningParameters.Insert("PrintParametersKey", UniqueKey);
		OpeningParameters.Insert("WindowOptionsKey", UniqueKey);

		StandardProcessing = False;
		If OpeningParameters.ReportType = "Additional" Then
			CommonClientServer.SupplementStructure(OpeningParameters, Parameters);
			SelectedForm = "Catalog.ReportsOptions.ObjectForm";
			Parameters.Insert("ReportFormOpeningParameters", OpeningParameters);
			Return;
		EndIf;
		SelectedForm = FullReportName + ".Form";
		CommonClientServer.SupplementStructure(Parameters, OpeningParameters);
	EndIf;
EndProcedure

#EndIf

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)

	Fields.Add("Description");
	Fields.Add("Ref");
	Fields.Add("Custom");
	Fields.Add("PredefinedOption");
	Fields.Add("ReportType");
	StandardProcessing = False;

EndProcedure

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)

	If ReportsOptionsServerCall.IsPredefinedReportOption(Data) Then
		Data.Ref = Data.PredefinedOption;
	EndIf;

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	If Common.SubsystemExists("StandardSubsystems.NationalLanguageSupport") Then
		ModuleNationalLanguageSupportClientServer = Common.CommonModule("NationalLanguageSupportClientServer");
		ModuleNationalLanguageSupportClientServer.PresentationGetProcessing(Data, Presentation, StandardProcessing);
	EndIf;
#Else
		If CommonClient.SubsystemExists("StandardSubsystems.NationalLanguageSupport") Then
			ModuleNationalLanguageSupportClientServer = CommonClient.CommonModule("NationalLanguageSupportClientServer");
			ModuleNationalLanguageSupportClientServer.PresentationGetProcessing(Data, Presentation,
				StandardProcessing);
		EndIf;
#EndIf

EndProcedure

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

////////////////////////////////////////////////////////////////////////////////
// Update handlers.

// This procedure registers data to be updated in the InfobaseUpdate exchange plan.
//  See "Parallel mode of deferred update" in the application development standards.
//
// Parameters:
//  Parameters - See InfobaseUpdate.MainProcessingMarkParameters
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	Query = New Query("
						  |SELECT
						  |	Variants.Ref
						  |FROM
						  |	Catalog.ReportsOptions AS Variants
						  |WHERE
						  |	Variants.Report = &UniversalReport
						  |	AND Variants.Custom
						  |
						  |UNION ALL
						  |
						  |SELECT
						  |	Variants.Ref
						  |FROM
						  |	Catalog.ReportsOptions AS Variants
						  |WHERE
						  |	Variants.Purpose = VALUE(Enum.ReportOptionPurposes.EmptyRef)
						  |");
	UniversalReport = Common.MetadataObjectID(Metadata.Reports.UniversalReport);
	Query.SetParameter("UniversalReport", UniversalReport);

	References = Query.Execute().Unload().UnloadColumn("Ref");

	InfobaseUpdate.MarkForProcessing(Parameters, References);
EndProcedure

// This procedure processes data registered in the InfobaseUpdate exchange plan.
//  See "Parallel mode of deferred update" in the application development standards.
//
// Parameters:
//  Parameters - See InfobaseUpdate.MainProcessingMarkParameters
//
Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	MetadataObject = Metadata.Catalogs.ReportsOptions;
	FullObjectName = MetadataObject.FullName();

	Processed = 0;
	Declined = 0;

	Purpose = ReportsOptionsInternal.AssigningDefaultReportOption();
	UniversalReport = Common.MetadataObjectID(Metadata.Reports.UniversalReport);

	Variant = InfobaseUpdate.SelectRefsToProcess(Parameters.Queue, FullObjectName);

	While Variant.Next() Do
		RepresentationOfTheReference = String(Variant.Ref);
		BeginTransaction();

		Try

			Block = New DataLock;
			LockItem = Block.Add(FullObjectName);
			LockItem.SetValue("Ref", Variant.Ref);
			Block.Lock();

			OptionObject = Variant.Ref.GetObject();
			If OptionObject = Undefined Then
				InfobaseUpdate.MarkProcessingCompletion(Variant.Ref);
				CommitTransaction();
				Continue;
			EndIf;

			OptionDataSourceSetup = False;
			If OptionObject.Report = UniversalReport And OptionObject.Custom Then
				OptionDataSourceSetup = True;
				OptionSettings = Reports.UniversalReport.OptionSettings(OptionObject);
				If OptionSettings = Undefined And ValueIsFilled(OptionObject.Purpose) Then
					InfobaseUpdate.MarkProcessingCompletion(Variant.Ref);
					CommitTransaction();
					Continue;
				EndIf;
				OptionObject.Settings = New ValueStorage(OptionSettings, New Deflation(9));
			EndIf;

			If Not ValueIsFilled(OptionObject.Purpose) Then
				OptionObject.Purpose = Purpose;
			EndIf;

			InfobaseUpdate.WriteData(OptionObject);

			Processed = Processed + 1;

			CommitTransaction();

		Except

			RollbackTransaction();
			
			// If a report option procession failed, try again.
			Declined = Declined + 1;

			If OptionDataSourceSetup Then
				CommentTemplate = NStr("vi = 'Không thể thiết lập nguồn dữ liệu cho phương án báo cáo %1.
										 |Có thể là nó bị hỏng và không thể khôi phục được.
										 |
										 |Thông tin kỹ thuật về sự cố: %2';
										 |ru = 'Не удалось установить источник данных варианта отчета %1.
										 |Возможно он поврежден и не подлежит восстановлению.
										 |
										 |Техническая информация о проблеме: %2';
										 |en = 'Cannot identify the data source for report option %1.
										 |It might be corrupted and cannot be recovered.
										 |
										 |Details: %2.'; fa = 'Cannot identify the data source for report option %1.
										 |It might be corrupted and cannot be recovered.
										 |
										 |Details: %2.';
										 |it = 'Non è stato possibile stabilire l''origine dei dati della variante del report %1. 
										 | È possibile che sia danneggiato e non soggetto ad un recupero. 
										 |
										 |Informazione tecnica sul problema: %2';
										 |pl = 'Nie udało się ustawić źródło danych wariantu raportu %1.
										 | Możliwe, że jest on uszkodzony i nie może być odzyskany. 
										 |
										 |Informacja techniczna o problemie: %2';
										 |tr = '%1 rapor seçeneğinin veri kaynağı yüklenemedi. 
										 |Bozuk ve düzeltilemiyor olabilir. 
										 |
										 |Sorun hakkında teknik bilgi: %2'");
			Else
				CommentTemplate = NStr("vi = 'Không thể đặt mục đích của phương án báo cáo %1.
										 |Có thể là nó đã bị hỏng và không thể khôi phục.
										 |
										 |Thông tin kỹ thuật về vấn đề: %2';
										 |ru = 'Не удалось установить назначение варианта отчета %1.
										 |Возможно он поврежден и не подлежит восстановлению.
										 |
										 |Техническая информация о проблеме: %2';
										 |en = 'Cannot identify the type of device for the %1 report option.
										 |It might be corrupted and cannot be recovered.
										 |
										 |Technical details: %2'; fa = 'Cannot identify the type of device for the %1 report option.
										 |It might be corrupted and cannot be recovered.
										 |
										 |Technical details: %2';
										 |it = 'Не удалось установить назначение варианта отчета %1.
										 |Возможно он поврежден и не подлежит восстановлению.
										 |
										 |Техническая информация о проблеме: %2';
										 |pl = 'Cannot identify the type of device for the %1 report option.
										 |It might be corrupted and cannot be recovered.
										 |
										 |Technical details: %2';
										 |tr = '%1 rapor seçeneğinin ataması yapılandırılamadı.
										 |Bozuk ve düzeltilemiyor olabilir. 
										 |
										 |Sorun hakkında teknik bilgi: %2'");
			EndIf;
			Comment = StringFunctionsClientServer.SubstituteParametersToString(
				CommentTemplate, RepresentationOfTheReference, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			
			InfobaseUpdate.WriteErrorToEventLog(
				Variant.Ref,
				RepresentationOfTheReference,
				Comment);
		EndTry;

	EndDo;

	Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue,
		FullObjectName);
	If Processed = 0 And Declined <> 0 Then
		MessageTemplate = NStr("vi = 'Không thể xử lý nhiều phương án báo cáo: %1';
								|ru = 'Не удалось обработать некоторые варианты отчетов: %1';
								|en = 'Couldn''t process (skipped) some report options: %1'; fa = 'Couldn''t process (skipped) some report options: %1';
								|it = 'Non è stato possibile elaborare alcune varianti di report: %1';
								|pl = 'Nie udało się przetworzyć niektórych wariantów raportów: %1';
								|tr = 'Bazı rapor seçenekleri işlenemedi:%1'");
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate, Declined);

		Raise MessageText;
	Else
		CommentTemplate = NStr("vi = 'Đã xử lý gói phương án báo cáo theo trình tự: %1';
								|ru = 'Обработан очередной пакет вариантов отчетов: %1';
								|en = 'Yet another batch of report options is processed: %1'; fa = 'Yet another batch of report options is processed: %1';
								|it = 'È stato elaborato un altro pacchetto di varianti di report: %1';
								|pl = 'Został przetworzony kolejny pakiet wariantów raportów: %1';
								|tr = 'Başka bir rapor seçeneği paketi işlendi:%1'");
		Comment = StringFunctionsClientServer.SubstituteParametersToString(CommentTemplate, Processed);
		WriteLogEvent(InfobaseUpdate.EventLogEvent(), EventLogLevel.Information,
			MetadataObject,, Comment);
	EndIf;

EndProcedure

#EndRegion

#EndIf

#EndIf