#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)

	MainCircuitSettings = SettingsComposer.GetSettings();
	DataSelectionValues = GetDataSelectionValues(MainCircuitSettings);

	MessageText = NStr("vi = 'Báo cáo không hỗ trợ nhận dữ liệu trước ngày bắt đầu kế toán tài sản dài hạn phiên bản 2.4 - %1';
						|ru = 'Отчет не поддерживает получение данных до даты начала учета внеоборотных активов версии 2.4 - %1';
						|en = 'Report does not support data retrieval prior to the commencement date of accounting of fixed assets 2.4 -%1'; fa = 'Report does not support data retrieval prior to the commencement date of accounting of fixed assets 2.4 -%1';
						|it = 'Il report non supporta l''acquisizione di dati prima della data di inizio della registrazione delle attività non correnti della versione 2.4 - %1';
						|pl = 'Raport nie obsługuje pobieranie danych przed datą rozpoczęcia ewidencji aktyw trwałych wersji 2.4 -%1';
						|tr = 'Rapor, duran varlıklar için muhasebeleştirme başlangıç tarihinden önce verilerin alınmasını desteklemiyor sürüm 2.4 - %1'");

	DateToCheck = MainCircuitSettings.DataParameters.Items.Find("Period");
	
	If Not ValueIsFilled(DateToCheck.Value) Then
		DateToCheck.Value.Date = CurrentSessionDate();
	EndIf;	
	
	NonCurrentAssetsInternal.CheckVersion24ReportPeriod(DateToCheck.Value.Date,
																DateToCheck.Value.Date,
																MessageText,
																Cancel);

	If Not DataSelectionValues.ShowACCalculation
		And Not DataSelectionValues.DisplayMACalculation Then
		MessageText = NStr("vi = 'Chọn những dữ liệu cần nhận: KTDN, KTQT.';
							|ru = 'Необходимо выбрать какие данные нужно получить: БУ, УУ.';
							|en = 'Select which data you need to get: LA, MA.'; fa = 'Select which data you need to get: LA, MA.';
							|it = 'È necessario selezionare i dati da ricevere: Contabilità, Contabilità Gestionale.';
							|pl = 'Należy wybrać jakie dane należy otrzymać: Ewidencja księgowa, Ewidencja zarządcza.';
							|tr = 'Hangi verilerin alınacağının seçilmesi gereklidir: GM, YM.'");
		Common.MessageToUser(MessageText,,,, Cancel);
	EndIf;

EndProcedure


Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)

	StandardProcessing = False;

	MainCircuitSettings = SettingsComposer.GetSettings();

	DataSelectionValues = GetDataSelectionValues(MainCircuitSettings);

	SetReportParameters(DataSelectionValues, MainCircuitSettings);
	
	ConfigureDisplayedReportMetrics(DataSelectionValues, MainCircuitSettings);

	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, MainCircuitSettings, DetailsData);

	DataCompositionProcessor = New DataCompositionProcessor;
	DataCompositionProcessor.Initialize(CompositionTemplate, Undefined, DetailsData, True);

	ProcessorOutputToTabularDocument = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	ProcessorOutputToTabularDocument.SetDocument(ResultDocument);
	ProcessorOutputToTabularDocument.Output(DataCompositionProcessor);

	AddInformationalMessageToHeader(ResultDocument, DataSelectionValues);
	
	CreateReportHeader(ResultDocument);

EndProcedure


#EndRegion

#Region Internal

// Settings for the General report form in the report Options subsystem.
//
// Parameters:
// Form - ClientApplicationForm - report form.
// VariantKey - String - The name of the predefined report variant or the unique ID of the custom one.
// Settings - See ReportsClientServer.GetDefaultReportSettings
//
Procedure DefineFormSettings(Form, VariantKey, Settings) Export

	Settings.Events.OnCreateAtServer = True;
	Settings.Events.OnLoadVariantAtServer = True;

EndProcedure


// Called in the handler of the report form event of the same name after executing the form code.
//
// Parameters:
// ThisForm - ClientApplicationForm - Report form:
// 	 * Parameters - Structure - may contain properties:
//				** CommandParameter -
//				** CommandDetails - Structure -
// Cancel - Boolean - passed from the handler parameters "as is".
// StandardProcessing - Boolean - Passed from the handler parameters "as is".
//
// See also:
// "Formaclientapplications.Joining the server" in the syntax assistant.
//
Procedure OnCreateAtServer(ThisForm, Cancel, StandardProcessing) Export

	Parameters = ThisForm.Parameters;

	If Parameters.Property("CommandParameter")
		And Parameters.Property("CommandDetails")
		And Parameters.CommandDetails.Property("AdditionalParameters") Then

		ThisForm.ParametersForm.PurposeUseKey = Parameters.CommandDetails.AdditionalParameters.CommandName;
		Parameters.PurposeUseKey = Parameters.CommandDetails.AdditionalParameters.CommandName;

	EndIf;

EndProcedure


// Called in the handler of the report form event of the same name after executing the form code.
//
// Parameters:
// Form - ClientApplicationForm - report form.
// NewDCSettings - DataCompositionSettings - Settings to upload to the Settings Composer.
//
// See Syntax Assistant "Managed Form extension for the report.Prizagruzkevariantanaserver" in the syntax assistant.
//
Procedure OnLoadVariantAtServer(Form, NewDCSettings) Export

	Report = Form.Report;
	FormSettingsComposer = Report.SettingsComposer; // DataCompositionSettingsComposer -

	SetReportPeriod(Form, FormSettingsComposer);

	NewDCSettings = FormSettingsComposer.Settings;

EndProcedure


#EndRegion

#Region Private

Procedure ConfigureDisplayedReportMetrics(DataSelectionValues, MainCircuitSettings)

	// Recursively set the visibility of the columns BU, UU depending on the value of the parameters.
	For Each LayoutTable In MainCircuitSettings.Structure Do
		
		If LayoutTable.Name = "Details" Then
			Continue;
		EndIf;
		
		For Each Column In LayoutTable.Columns Do
			For Each ColumnData In Column.Selection.Items Do
				For Each ColumnDataElement In ColumnData.Items Do
					
					If ColumnDataElement.Title = NStr("vi = 'KTDN';
														|ru = 'БУ';
														|en = 'LA'; fa = 'محلی';
														|it = 'Contabilità civilistica';
														|pl = 'EK';
														|tr = 'Genel Muhasebe'") Then
						ColumnDataElement.Use = DataSelectionValues.ShowACCalculation;
					ElsIf ColumnDataElement.Title = NStr("vi = 'KTQT';
														|ru = 'УУ';
														|en = 'MA'; fa = 'مدیریت';
														|it = 'Contabilità Gestionale';
														|pl = 'EZ';
														|tr = 'Yönetim Muhasebesi'") Then
						ColumnDataElement.Use = DataSelectionValues.DisplayMACalculation;
					EndIf;
					
				EndDo;
			EndDo;
		EndDo;
	EndDo;	
	
EndProcedure	

Procedure CreateReportHeader(TabDoc)
	
	ListOfCellGroups = New Array;
	
	ListOfCellGroups.Add(NStr("vi = 'Chỉ tiêu';
								|ru = 'Показатели';
								|en = 'Indicators'; fa = 'شاخص‌ها';
								|it = 'Indici';
								|pl = 'Data przyjęcia do ewidencji';
								|tr = 'Göstergeler'"));
	ListOfCellGroups.Add(NStr("vi = 'Giá trị ghi sổ có tính đến giảm giá';
								|ru = 'Балансовая стоимость с учетом обесценения';
								|en = 'Book value including impairment'; fa = 'ارزش دفتری شامل کاهش ارزش';
								|it = 'Costo bilanciato con il calcolo della svalutazione';
								|pl = 'Wartość bilansowa z uwzględnieniem utraty wartości';
								|tr = 'Değer kaybı dahil maliyet değeri'"));
	ListOfCellGroups.Add(NStr("vi = 'Khấu hao lũy kế';
								|ru = 'Накопленная амортизация';
								|en = 'Accumulated depreciation'; fa = 'استهلاک انباشته';
								|it = 'Ammortamento cumulato';
								|pl = 'Amortyzacja skumulowana';
								|tr = 'Birikmiş amortisman'"));
	ListOfCellGroups.Add(NStr("vi = 'Điều chỉnh tích lũy khấu hao';
								|ru = 'Накопленная корректировка обесценения';
								|en = 'Accumulated impairment adjustment'; fa = 'تعدیل انباشته کاهش ارزش';
								|it = 'Aggiustamento cumulativo di svalutazione';
								|pl = 'Skumulowana korekta utraty wartości';
								|tr = 'Toplam değer kaybı düzeltmesi'"));
	ListOfCellGroups.Add(NStr("vi = 'Khấu hao cho phép khôi phục';
								|ru = 'Обесценение, доступное для восстановления';
								|en = 'Impairment available for reversal'; fa = 'کاهش ارزش در دسترس برای برگشت';
								|it = 'Svalutazione disponibile per il ripristino';
								|pl = 'Utrata wartości, dostępna do przywrócenia';
								|tr = 'İyileştirilebilecek değer kaybı'"));
	ListOfCellGroups.Add(NStr("vi = 'Giảm giá';
								|ru = 'Обесценение';
								|en = 'Impairment'; fa = 'کاهش ارزش';
								|it = 'Svalutazione';
								|pl = 'Utrata wartości';
								|tr = 'Değer kaybı'"));

	
	ListOfSubordinateCells = New Array;
	ListOfSubordinateCells.Add(NStr("vi = 'KTDN';
									|ru = 'БУ';
									|en = 'LA'; fa = 'محلی';
									|it = 'Contabilità civilistica';
									|pl = 'EK';
									|tr = 'Genel Muhasebe'"));
	ListOfSubordinateCells.Add(NStr("vi = 'KTQT';
									|ru = 'УУ';
									|en = 'MA'; fa = 'مدیریت';
									|it = 'Contabilità Gestionale';
									|pl = 'EZ';
									|tr = 'Yönetim Muhasebesi'"));
	
	MergeSubordinateCells(TabDoc, ListOfCellGroups, ListOfSubordinateCells);
	
EndProcedure

Function GetDataSelectionValues(MainCircuitSettings)

	FilterItems1 = MainCircuitSettings.Filter.Items;

	DataSelectionValues = New Structure;

	DataSelectionValues.Insert("CompaniesList", TMReportsServer.FilterValue("Organization", FilterItems1));
	
	If DataSelectionValues.CompaniesList.Count() = 0 Then
		DataSelectionValues.CompaniesList = NonCurrentAssetsInternal.ListOfAllowedOrganizations();
	EndIf;

	DataSelectionValues.Insert("ListOfVNA", TMReportsServer.FilterValue("NonCurrentAsset", FilterItems1));

	ShowACCalculation = TMReportsServer.ParameterValue(MainCircuitSettings, "ShowACCalculation", False);
	DisplayMACalculation = TMReportsServer.ParameterValue(MainCircuitSettings, "DisplayMACalculation", False);

	DataSelectionValues.Insert("ShowACCalculation", ShowACCalculation);
	DataSelectionValues.Insert("DisplayMACalculation", DisplayMACalculation);
	
	
	
	DataSelectionValues.Insert("Period", MainCircuitSettings.DataParameters.Items.Find("Period").Value);

	Return DataSelectionValues;

EndFunction


Procedure SetReportParameters(DataSelectionValues, MainCircuitSettings)

	Period = Date(1,1,1);

	If TypeOf(DataSelectionValues.Period) = Type("StandardBeginningDate") Then
		Period = DataSelectionValues.Period.Date;
	EndIf;
	
	If Period = Date(1,1,1) Then
		Period = EndOfDay(CurrentSessionDate());
	EndIf; 
	
	DataCompositionClientServer.SetParameter(MainCircuitSettings, "Period", Period);

	BusinessTransactionsImpairmentCharge = New Array;
	BusinessTransactionsImpairmentCharge.Add(Catalogs.BusinessTransactionsSettings.EnterBalanceOfFAImpairment);
	BusinessTransactionsImpairmentCharge.Add(Catalogs.BusinessTransactionsSettings.EnterBalanceOfIAImpairment);
	BusinessTransactionsImpairmentCharge.Add(Catalogs.BusinessTransactionsSettings.FAImpairment);
	BusinessTransactionsImpairmentCharge.Add(Catalogs.BusinessTransactionsSettings.ImpairmentIA);
	
	DataCompositionClientServer.SetParameter(	MainCircuitSettings, 
														"BusinessTransactionSettingsImpairmentCharge", 
														BusinessTransactionsImpairmentCharge);


EndProcedure


Procedure SetReportPeriod(Form, FormSettingsComposer)
	Return;
EndProcedure


Procedure AddInformationalMessageToHeader(TabDoc, DataSelectionValues)

	IssuesList = New Array;

	CheckRelevanceOfDepreciationCalculation(DataSelectionValues, IssuesList);

	If IssuesList.Count() = 0 Then
		Return;
	EndIf;

	IssuesList = TMCommonUse.DeleteDuplicateElementsFromArray(IssuesList);

	MessageText = StrConcat(IssuesList, Chars.LF);

	TabDoc.Area("R1C1").Text = MessageText;
	TabDoc.Area("R1C1").TextColor = Metadata.StyleItems.TextColorIssue.Value;
	TabDoc.Area(1, 1, 1, ).RowHeight = 0;

EndProcedure


Procedure CheckRelevanceOfDepreciationCalculation(DataSelectionValues, IssuesList)

	InformationRegisters.IntangibleAssetAmortizationPackages.CreateDepreciationPackages(DataSelectionValues.CompaniesList);

	QueryText =
	"SELECT DISTINCT
	|	DocumentDepreciation.Organization AS Organization
	|FROM
	|	Document.FixedAssetsDepreciationCharge2_4 AS DocumentDepreciation
	|		INNER JOIN InformationRegister.JobsForCalculatingFixedAssetDepreciation AS JobsForCalculating
	|		ON (JobsForCalculating.Organization = DocumentDepreciation.Organization)
	|		AND (JobsForCalculating.Month <= DocumentDepreciation.Date)
	|		LEFT JOIN InformationRegister.FixedAssetDepreciationPackages AS FixedAssetDepreciationPackages
	|		ON FixedAssetDepreciationPackages.Organization = JobsForCalculating.Organization
	|		AND FixedAssetDepreciationPackages.PackageNumber = JobsForCalculating.PackageNumber
	|		AND &SelectionAccordingToVNAList
	|WHERE
	|	DocumentDepreciation.Organization IN (&CompaniesList)
	|	AND (NOT &SelectionAccordingToVNAList
	|	OR FixedAssetDepreciationPackages.FixedAsset IN (&ListOfVNA))
	|	AND DocumentDepreciation.Posted
	|	AND (DocumentDepreciation.Date >= &BeginOfPeriod
	|	OR &BeginOfPeriod = DATETIME(1, 1, 1))
	|	AND (DocumentDepreciation.Date <= &PeriodEnding
	|	OR &PeriodEnding = DATETIME(1, 1, 1))
	|
	|UNION
	|
	|SELECT DISTINCT
	|	DocumentDepreciation.Organization AS Organization
	|FROM
	|	Document.IntangibleAssetsAmortizationCharge2_4 AS DocumentDepreciation
	|		INNER JOIN InformationRegister.JobsForCalculatingIntangibleAssetAmortization AS JobsForCalculating
	|		ON JobsForCalculating.Organization = DocumentDepreciation.Organization
	|		AND JobsForCalculating.Month <= DocumentDepreciation.Date
	|		LEFT JOIN InformationRegister.IntangibleAssetAmortizationPackages AS IntangibleAssetAmortizationPackages
	|		ON IntangibleAssetAmortizationPackages.Organization = JobsForCalculating.Organization
	|		AND IntangibleAssetAmortizationPackages.PackageNumber = JobsForCalculating.PackageNumber
	|		AND &SelectionAccordingToVNAList
	|WHERE
	|	DocumentDepreciation.Organization IN (&CompaniesList)
	|	AND (NOT &SelectionAccordingToVNAList
	|	OR IntangibleAssetAmortizationPackages.IntangibleAsset IN (&ListOfVNA))
	|	AND DocumentDepreciation.Posted
	|	AND (DocumentDepreciation.Date >= &BeginOfPeriod
	|	OR &BeginOfPeriod = DATETIME(1, 1, 1))
	|	AND (DocumentDepreciation.Date <= &PeriodEnding
	|	OR &PeriodEnding = DATETIME(1, 1, 1))";

	Query = New Query(QueryText);
	Query.SetParameter("CompaniesList", DataSelectionValues.CompaniesList);
	Query.SetParameter("BeginOfPeriod", DataSelectionValues.Period.Date);
	Query.SetParameter("PeriodEnding", DataSelectionValues.Period.Date);
	Query.SetParameter("ListOfVNA", DataSelectionValues.ListOfVNA);
	Query.SetParameter("SelectionAccordingToVNAList", ValueIsFilled(DataSelectionValues.ListOfVNA));

	Result = Query.Execute();

	If Result.IsEmpty() Then
		Return;
	EndIf;

	IssuesList.Add(NStr("vi = 'Chưa cập nhật tính khấu hao:';
						|ru = 'Расчет амортизации не актуален:';
						|en = 'Depreciation calculation is not relevant:'; fa = 'Depreciation calculation is not relevant:';
						|it = 'Il calcolo dell''ammortamento è obsoleto:';
						|pl = 'Obliczanie amortyzacji jest nieaktualne:';
						|tr = 'Amortisman hesabı alakasız:'"));

	Selection = Result.Select();
	While Selection.Next() Do
		MessageText = " - " + NStr("vi = 'đối với doanh nghiệp ""%1"" cần thực hiện đóng tháng';
									|ru = 'для организации ""%1"" необходимо выполнить закрытие месяца';
									|en = 'for the company ""%1"" you must perform a month-end closing'; fa = 'for the company ""%1"" you must perform a month-end closing';
									|it = 'per l''azienda ""%1"" è necessario effettuare la chiusura di fine periodo';
									|pl = 'dla firmy ""%1"" należy wykonać zamknięcie miesiąca';
									|tr = '- ""%1"" iş yeri için ay sonu kapanışı işleminin gerçekleştirilmesi gerekmektedir'");
		MessageText = StrTemplate(MessageText, Selection.Organization);
		IssuesList.Add(MessageText);
	EndDo;

EndProcedure

// Combines subordinate cells in the report.
//
// Parameters:
//  TabDoc					 - SpreadsheetDocument - Table document of the report.
//  ListOfCellGroups		 - Array			 - List of cell groups.
//  ListOfSubordinateCells	 - Array			 - A list of cells that will be combined with a group of cells.
//
Procedure MergeSubordinateCells(TabDoc, ListOfCellGroups, ListOfSubordinateCells) Export
	
	HeaderFound = False;
	
	NumberOfGroupsOfMergedCells = ListOfCellGroups.Count();
	NumberOfMergedCells      = ListOfSubordinateCells.Count();
		
	For IndRow = 1 To TabDoc.TableHeight Do
		
		For HeaderStartColumn = 1 To TabDoc.TableWidth Do
			
			TableCellArea = TabDoc.Area(IndRow, HeaderStartColumn);
			HeaderFound = ListOfCellGroups.Find(TableCellArea.Text) <> Undefined;
			If HeaderFound Then
				Break;
			EndIf;
		EndDo;
				
		If HeaderFound Then
			
			For IndKol = HeaderStartColumn To TabDoc.TableWidth Do
				
				Offset = 0;
				
				For Cnt = 0 To NumberOfGroupsOfMergedCells Do
					
					TableCellArea = TabDoc.Area(IndRow + Cnt, IndKol);
					
					If ListOfCellGroups.Find(TableCellArea.Text) <> Undefined Then
						Break; // We found a group with subordinate cells.
					EndIf;
					
					Offset = Offset + 1;
					
				EndDo;
				
				// Processing of subordinate cells of the group.
				TableCellArea = TabDoc.Area(
									IndRow + Offset, 
									IndKol, 
									IndRow + Offset, 
									IndKol); // Group cell. 
									
				TitleText = TableCellArea.Text; // The text of the group cell.
				
				HeaderHeight = 0;
				For IndexOf = 1 To NumberOfMergedCells Do
					
					TableCellArea = TabDoc.Area(
											IndRow+IndexOf+Offset, 
											IndKol, 
											IndRow+IndexOf+Offset, 
											IndKol);
											
					NextCell = TableCellArea.Text; // Text of the subordinate cell
					
					If ListOfSubordinateCells.Find(NextCell) = Undefined Then
						Break;
					EndIf;
					
					HeaderHeight = HeaderHeight + 1;
					
				EndDo;
				
				MergedArea = TabDoc.Area(IndRow+Offset, IndKol, IndRow + HeaderHeight + Offset, IndKol);
				MergedArea.Merge();
				MergedArea.Text = TitleText;
				MergedArea.TextPlacement = SpreadsheetDocumentTextPlacementType.Wrap;
				
			EndDo; 
				
			Return;
			
		EndIf;
		
	EndDo;
	
EndProcedure


#EndRegion

#EndIf
