
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	AddressBudgetPopulationDimension = Undefined;
	If Not Parameters.Property("BudgetProfile", BudgetProfile)
		And Not Parameters.Property("BudgetBalanceItem", BudgetBalanceItem)
	 Or Not Parameters.Property("BudgetingModel", BudgetingModel)
	 Or Not Parameters.Property("AddressBudgetPopulationDimension", AddressBudgetPopulationDimension)
	 Or Not Parameters.Property("RowKey", RowKey) Then
		MessageText = NStr("vi = 'Không xem xét mở trực tiếp biểu mẫu này. Để mở biểu mẫu, bạn có thể sử dụng nút giá trị mở trong cột ""Mặc định đo lường"" trong biểu mẫu để nhập ngân sách.';
							|ru = 'Непосредственное открытие этой формы не предусмотрено. Для открытия формы можно воспользоваться кнопкой открытия значения в колонке ""Настройки измерений по умолчанию"" в форме настроек ввода бюджетов.';
							|en = 'Application cannot open this form explicitly. It opens implicitly when you select the value opening button in the ""Default dimension settings"" column in the form of budget input settings.'; fa = 'Application cannot open this form explicitly. It opens implicitly when you select the value opening button in the ""Default dimension settings"" column in the form of budget input settings.';
							|it = 'L''apertura diretta di questo modulo non è prevista. Per aprire il modulo bisogna utilizzare il tasto di apertura del valore nella colonna ""Impostazioni di rilevamento per default"" nel modulo delle impostazioni di inserimento dei budget.';
							|pl = 'Bezpośrednie otwarcie tego formularza nie jest przewidziane. Aby otworzyć formularz, możesz użyć przycisku otwarcia wartości w kolumnie ""Domyślne ustawienia pomiarów"" w formularzu ustawień wprowadzania budżetów.';
							|tr = 'Bu formun doğrudan açılması sağlanamadı. Formun açılması için ""Varsayılan boyut ayarlarına göre"" rapor ayarları bütçe girişinde yer alan sütunda değeri açma butonunda faydalanabilirsiniz.'");
		Raise MessageText;
	EndIf;
	
	BudgetPopulationDimension.Load(GetFromTempStorage(AddressBudgetPopulationDimension));
	
	OptionsParameters = New Structure("BudgetingModel", BudgetingModel);
	SetFormFunctionalOptionParameters(OptionsParameters);
	
	If ValueIsFilled(BudgetProfile) Then
		BudgetDetails = Common.ObjectAttributeValue(BudgetProfile,
			"HeaderDimensions").Unload().UnloadColumn("DimensionKind");
		TypesOfAnalystValues = Common.ObjectsAttributeValue(BudgetDetails, "ValueType");
		For Cnt = 1 To BudgetDetails.Count() Do
			DimensionKind = BudgetDetails[Cnt - 1];
			Items["AnalyticsForFillingInBudgetAnalytics" + Cnt].Title = String(DimensionKind);
			Items["AnalyticsForFillingInBudgetAnalytics" + Cnt].TypeRestriction = TypesOfAnalystValues.Get(DimensionKind);
		EndDo;
	Else
		BudgetDetails = New Array;
	EndIf;
	
	NumberOfAnalysts = BudgetDetails.Count();
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	If NumberOfAnalysts < MaximumNumberOfAnalysts Then
		For Cnt = NumberOfAnalysts + 1 To MaximumNumberOfAnalysts Do
			Items["BudgetFillingAnalyticsAnalyticsGroup" + Cnt].Visible = False;
			For Each Page1 In BudgetPopulationDimension Do
				Page1["Dimension" + Cnt] = Undefined;
				Page1["AvailabilityOfAnalytics_" + Cnt] = False;
			EndDo;
		EndDo;
	EndIf;
	
	FOParameters = New Structure("BudgetingModel", BudgetingModel);
	GenerateBudgetsByCompanies = GetFunctionalOption("GenerateBudgetsByCompanies", FOParameters);
	GenerateBudgetsByBusinessUnits = GetFunctionalOption("GenerateBudgetsByBusinessUnits", FOParameters);
	
	For Each Page1 In BudgetPopulationDimension Do
		If Not GenerateBudgetsByCompanies Then
			Page1.Organization = Undefined;
			Page1.AvailabilityCompany = False;
			Items.BudgetPopulationDimensionGroupCompany.Visible = False;
		EndIf;
		
		If Not GenerateBudgetsByBusinessUnits Then
			Page1.Department = Undefined;
			Page1.AvailabilityDepartment = False;
			Items.BudgetPopulationDimensionGroupDepartment.Visible = False;
		EndIf;
	EndDo;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	Items.BudgetPopulationDimension.RowFilter = New FixedStructure("RowKey", RowKey);

EndProcedure

#EndRegion

#Region EventHandlersForFormElements

&AtClient
Procedure BudgetPopulationDimensionOnStartEdit(Item, NewRow, Copy)
	
	If NewRow Then
		Items.BudgetPopulationDimension.CurrentData.RowKey = RowKey;
	EndIf;

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ShouldSaveSettings(Command)
	
	Cancel = False; 
	HandlingFillVerificationOnClient(Cancel);
	If Not Cancel Then 
		Result = New Structure("Address,DimensionSettingLineKey", SaveSettingsAtServer(), RowKey );
		Close(Result);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Function SaveSettingsAtServer()
	
	Return PutToTempStorage(BudgetPopulationDimension.Unload(), Address);
	
EndFunction

&AtClient
Procedure HandlingFillVerificationOnClient(Cancel)
	
	Cnt = 0;
	For Each Page1 In BudgetPopulationDimension Do
		
		If Page1.RowKey = RowKey Then
			// The script is not checked when Balances of calculated indicators are entered
			If Not ValueIsFilled(Page1.Scenario) And Not ValueIsFilled(BudgetBalanceItem) Then
				MessageText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Chưa điền kịch bản trong dòng %1';
						|ru = 'В строке %1 не заполнен сценарий';
						|en = 'Scenario in line %1 is not filled in'; fa = 'Scenario in line %1 is not filled in';
						|it = 'Nella riga %1 non è compilato lo script';
						|pl = 'W wierszu %1 nie jest wypełniony scenariusz';
						|tr = 'Satır %1''de senaryo doldurulmamış'"),
					Cnt+1);
				DataPath = StringFunctionsClientServer.SubstituteParametersToString(
					"BudgetPopulationDimension[%1].Scenario",
					Cnt); 
				CommonClient.MessageToUser(MessageText,,, DataPath, Cancel);
			EndIf;
			
			If GenerateBudgetsByCompanies And Not ValueIsFilled(Page1.Organization) Then
				MessageText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Dòng doanh nghiệp %1 trống';
						|ru = 'В строке %1 не заполнена организация';
						|en = 'Company in line %1 is not filled in'; fa = 'Company in line %1 is not filled in';
						|it = 'Nella riga %1 non è compilata l''azienda';
						|pl = 'W wierszu %1 nie jest wypełniona firma';
						|tr = '%1 satırında iş yeri doldurulmadı'"),
					Cnt+1);
				DataPath = StringFunctionsClientServer.SubstituteParametersToString(
					"BudgetPopulationDimension[%1].Organization",
					Cnt);
				CommonClient.MessageToUser(MessageText,,, DataPath, Cancel);
			EndIf;
			
			If GenerateBudgetsByBusinessUnits And Not ValueIsFilled(Page1.Department) Then
				MessageText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Chưa điền bộ phận trong dòng %1';
						|ru = 'В строке %1 не заполнено подразделение';
						|en = 'Business unit in line %1 is not filled in'; fa = 'Business unit in line %1 is not filled in';
						|it = 'Nella riga %1 non è compilato il reparto';
						|pl = 'W wierszu %1 nie jest wypełniony dział';
						|tr = '%1 satırında departman doldurulmamış'"),
					Cnt+1);
				DataPath = StringFunctionsClientServer.SubstituteParametersToString(
					"BudgetPopulationDimension[%1].Department",
					Cnt);	
				CommonClient.MessageToUser(MessageText,,, DataPath, Cancel);
			EndIf;
			Cnt = Cnt + 1;	
		EndIf;
		
	EndDo;

EndProcedure

&AtClient
Procedure SetRemoveDimensionChangePossibility(Command)
	
	CurrentData = Items.BudgetPopulationDimension.CurrentData;
	If CurrentData = Undefined Then 
		Return;
	EndIf;
	
	CurCell_ = Items.BudgetPopulationDimension.CurrentItem;
	If CurCell_ = Undefined Then
		Return;
	EndIf;
	
	AvailabilityPropsName = AvailabilityPropsName(CurCell_.Name);
	CurrentData[AvailabilityPropsName] = Not CurrentData[AvailabilityPropsName];
	
EndProcedure

&AtClient
Function AvailabilityPropsName(CellName)
	
	If CellName = "BudgetPopulationDimensionScenario" Then
		Return "AvailabilityScenario"
	ElsIf CellName = "BudgetPopulationDimensionOrganization" Then
		Return "AvailabilityCompany"
	ElsIf CellName = "BudgetPopulationDimensionDepartment" Then
		Return "AvailabilityDepartment"
	ElsIf CellName = "AnalyticsForFillingInBudgetAnalytics1" Then
		Return "AvailabilityOfAnalytics_1"
	ElsIf CellName = "AnalyticsForFillingInBudgetAnalytics2" Then
		Return "AvailabilityOfAnalytics_2"
	ElsIf CellName = "AnalyticsForFillingInBudgetAnalytics3" Then
		Return "AvailabilityOfAnalytics_3"
	ElsIf CellName = "AnalyticsForFillingInBudgetAnalytics4" Then
		Return "AvailabilityOfAnalytics_4"
	ElsIf CellName = "AnalyticsForFillingInBudgetAnalytics5" Then
		Return "AvailabilityOfAnalytics_5"
	ElsIf CellName = "AnalyticsForFillingInBudgetAnalytics6" Then
		Return "AvailabilityOfAnalytics_6"
	EndIf;

EndFunction

#EndRegion