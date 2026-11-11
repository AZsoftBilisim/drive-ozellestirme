///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Items.InfoLoopDetected.Title = StringFunctions.FormattedString(
		Items.InfoLoopDetected.Title, 
		DataExchangeLoopControl.AllLoopedNodesPresentation());
		
	Query = New Query;
	Query.Text = 
	"SELECT
	|	Settings.InfobaseNode AS InfobaseNode,
	|	Settings.ExchangeDataRegistrationOnLoop AS ExchangeDataRegistrationOnLoop,
	|	Settings.DisableSynchronizationCircuitMonitoring AS DisableSynchronizationCircuitMonitoring
	|FROM
	|	InformationRegister.CommonInfobasesNodesSettings AS Settings
	|WHERE
	|	Settings.IsLoopDetected
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 1
	|	Settings.InfobaseNode AS InfobaseNode
	|FROM
	|	InformationRegister.CommonInfobasesNodesSettings AS Settings
	|WHERE
	|	Settings.DisableSynchronizationCircuitMonitoring";
	
	QueryResult = Query.ExecuteBatch();
	
	NodeTable_.Load(QueryResult[0].Unload());
	If NodeTable_.Count() > 0 Then
		
		Items.GroupThisInfobase.Visible = True;
		Items.FormSwitchControl.Visible = False;
		Items.GroupAnotherInfobase.Visible = False;
		
	Else
		
		Items.GroupThisInfobase.Visible = False;
		Items.FormSwitchControl.Visible = True;
		Items.GroupAnotherInfobase.Visible = True;
		
		Items.InformationAnotherInfobase.Title = StringFunctions.FormattedString(
			Items.InformationAnotherInfobase.Title,
			DataExchangeLoopControl.InfobaseWithSuspendedRegistrationPresentation());
		
	EndIf;
	
	SynchronizationLoopMonitoringIsEnabled = QueryResult[1].IsEmpty();
	LoopingWarningIsHidden = DataExchangeLoopControl.LoopingWarningIsHiddenFromUser();
	
	SetConditionalAppearance();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	FormElementHeaders();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersNodeTable_

&AtClient
Procedure NodeTable_DisableSynchronizationCircuitMonitoringOnChange(Item)
	
	CurrentRowData = Items.NodeTable_.CurrentData;
	If CurrentRowData = Undefined Then
		
		Return;
		
	EndIf;
	
	LoopControlManagement(CurrentRowData.InfobaseNode, CurrentRowData.DisableSynchronizationCircuitMonitoring);
	
EndProcedure

&AtClient
Procedure NodeTable_Selection(Item, RowSelected, Field, StandardProcessing)
	
	If Field.Name = "NodeTable_ExchangeDataRegistrationOnLoop" Then
		
		String = NodeTable_.FindByID(RowSelected);
		String.ExchangeDataRegistrationOnLoop = Not String.ExchangeDataRegistrationOnLoop;
		
		PauseResumeRegistration(String.InfobaseNode, String.ExchangeDataRegistrationOnLoop);
		
	ElsIf Field.Name = "NodeTable_UnregistreredData" Then
		
		String = NodeTable_.FindByID(RowSelected);
		FormParameters = New Structure("InfobaseNode", String.InfobaseNode);
		
		OpenForm("InformationRegister.ObjectsUnregisteredDuringLoop.ListForm", FormParameters);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CloseForm(Command)
	
	Notify("ChangingVisibilityOfLoopingWarnings");
	Close();
	
EndProcedure

&AtClient
Procedure SynchronizationCircuit(Command)
	
	OpenForm("InformationRegister.SynchronizationCircuit.ListForm");
	
EndProcedure

&AtClient
Procedure SwitchControl(Command)
	
	SwitchControlAtServer();
	FormElementHeaders();
	
EndProcedure

&AtClient
Procedure DisplayLoopingWarning(Command)
	
	LoopingWarningIsHidden = Not LoopingWarningIsHidden;
	DataExchangeServerCall.HideShowLoopingWarningFromUser(LoopingWarningIsHidden);
	FormElementHeaders();
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure FormElementHeaders()
	
	If SynchronizationLoopMonitoringIsEnabled = True Then
		
		LineHeader = NStr("vi = 'Tắt sử dụng kiểm soát';
							|ru = 'Отключить контроль';
							|en = 'Disable control'; fa = 'غیرفعال‌سازی کنترل';
							|it = 'Отключить контроль';
							|pl = 'Disable control';
							|tr = 'Kontrolü etkinleştir'", CommonClient.DefaultLanguageCode());
		
	Else
		
		LineHeader = NStr("vi = 'Bật sử dụng kiểm soát';
							|ru = 'Включить контроль';
							|en = 'Enable control'; fa = 'Enable control';
							|it = 'Включить контроль';
							|pl = 'Enable control';
							|tr = 'Kontrolü devre dışı bırak'", CommonClient.DefaultLanguageCode());
		
	EndIf;
	
	Items.FormSwitchControl.Title = LineHeader;
	
	
	If LoopingWarningIsHidden = True Then
		
		LineHeader = NStr("vi = 'Hiển thị cảnh báo về việc lặp';
							|ru = 'Отображать предупреждение о зацикливании';
							|en = 'Display a warning about looping'; fa = 'Display a warning about looping';
							|it = 'Отображать предупреждение о зацикливании';
							|pl = 'Display a warning about looping';
							|tr = 'Döngü uyarısını göster'", CommonClient.DefaultLanguageCode());
		
	Else
		
		LineHeader = NStr("vi = 'Ẩn cảnh báo về việc lặp';
							|ru = 'Скрыть предупреждение о зацикливании';
							|en = 'Hide a warning about looping'; fa = 'Hide a warning about looping';
							|it = 'Скрыть предупреждение о зацикливании';
							|pl = 'Hide a warning about looping';
							|tr = 'Döngü uyarısını gizle'", CommonClient.DefaultLanguageCode());
		
	EndIf;
	
	Items.FormDisplayLoopingWarning.Title = LineHeader;
	
EndProcedure

&AtServer
Function SubAssetsWithDetectedLooping()
	
	Query = New Query(
	"SELECT DISTINCT
	|	SynchronizationCircuit.InfobaseNode AS ExchangePlanNode
	|FROM
	|	InformationRegister.SynchronizationCircuit AS SynchronizationCircuit
	|		INNER JOIN InformationRegister.CommonInfobasesNodesSettings AS CommonInfobasesNodesSettings
	|		ON SynchronizationCircuit.InfobaseNode = CommonInfobasesNodesSettings.InfobaseNode
	|WHERE
	|	NOT SynchronizationCircuit.InfobaseNode IS NULL");
	
	Return Query.Execute().Unload().UnloadColumn("ExchangePlanNode");
	
EndFunction

&AtServer
Procedure PauseResumeRegistration(InfobaseNode, ExchangeDataRegistrationOnLoop)
	
	SetPrivilegedMode(True);
	
	Try 
		
		InformationRegisters.CommonInfobasesNodesSettings.SetLoop(
			InfobaseNode,,
			ExchangeDataRegistrationOnLoop);
		
	Except
		
		WriteLogEvent(, EventLogLevel.Error,,, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		
	EndTry;
	
EndProcedure

&AtServer
Procedure SwitchControlAtServer()
	
	SubAssetsWithDetectedLooping = SubAssetsWithDetectedLooping();
	For Each ExchangePlanNode In SubAssetsWithDetectedLooping Do
		
		InformationRegisters.CommonInfobasesNodesSettings.SetLoop(ExchangePlanNode, , , SynchronizationLoopMonitoringIsEnabled);
		
	EndDo;
	
	SynchronizationLoopMonitoringIsEnabled = Not SynchronizationLoopMonitoringIsEnabled;
	If Not SynchronizationLoopMonitoringIsEnabled Then
		
		DataExchangeServerCall.HideShowLoopingWarningFromUser(True);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	// Resume registration
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("NodeTable_ExchangeDataRegistrationOnLoop");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("NodeTable_.ExchangeDataRegistrationOnLoop");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Text = NStr("vi = 'Phục hồi ghi nhận';
				|ru = 'Возобновить регистрацию';
				|en = 'Resume registration'; fa = 'Resume registration';
				|it = 'Ripristinare la registrazione';
				|pl = 'Wznów rejestrację';
				|tr = 'Kaydı sürdür'");
	Item.Appearance.SetParameterValue("Text", Text);
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("TextColor", WebColors.Blue);
	
	// Terminate registration
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("NodeTable_ExchangeDataRegistrationOnLoop");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("NodeTable_.ExchangeDataRegistrationOnLoop");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Text = NStr("vi = 'Dừng ghi nhận';
				|ru = 'Приостановить регистрацию';
				|en = 'Terminate registration'; fa = 'Terminate registration';
				|it = 'Sospendere la registrazione';
				|pl = 'Wstrzymaj rejestrację';
				|tr = 'Kaydı askıya al'");
	Item.Appearance.SetParameterValue("Text", Text);
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("TextColor", WebColors.Blue);

	// Navigate
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("NodeTable_UnregistreredData");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("NodeTable_.InfobaseNode");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Text = NStr("vi = 'Chuyển đến';
				|ru = 'Перейти';
				|en = 'Navigate'; fa = 'پیمایش';
				|it = 'Vai a';
				|pl = 'Przejdź';
				|tr = 'Git'");
	Item.Appearance.SetParameterValue("Text", Text);
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("TextColor", WebColors.Blue);
	
EndProcedure

&AtServer
Procedure LoopControlManagement(Val InfobaseNode, Val DisableSynchronizationCircuitMonitoring)
	
	SetPrivilegedMode(True);
	
	Try 
		
		InformationRegisters.CommonInfobasesNodesSettings.SetLoop(
			InfobaseNode,,, DisableSynchronizationCircuitMonitoring);
		
	Except
		
		WriteLogEvent(, EventLogLevel.Error,,, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		
	EndTry;
	
	
EndProcedure

#EndRegion
