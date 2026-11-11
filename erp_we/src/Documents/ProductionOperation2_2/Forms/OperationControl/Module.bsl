
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	Parameters.Property("ProductionOperation", ProductionOperation);
	
	AttributesStructure1 = New Structure;
	AttributesStructure1.Insert("Operation");
	AttributesStructure1.Insert("OperationName_", "Description");
	AttributesStructure1.Insert("OperationAsOutputReference");
	AttributesStructure1.Insert("FollowUp");
	
	For Each KeyAndValue In AttributesStructure1 Do
		If Parameters.Property(KeyAndValue.Key, ThisObject[KeyAndValue.Key]) Then
			AttributesStructure1.Delete(KeyAndValue.Key);
		EndIf;
	EndDo;
	
	If AttributesStructure1.Count() > 0 Then
		ValueOfBankingDetails = Common.ObjectAttributesValues(ProductionOperation, AttributesStructure1);
		FillPropertyValues(ThisObject, ValueOfBankingDetails);
	EndIf;
	
	If Not ValueIsFilled(OperationName_) Then
		OperationName_ = Operation;
	EndIf;
	
	Title = StrTemplate(NStr("vi = 'Kiểm soát giao dịch ""%1""';
							|ru = 'Контроль операции ""%1""';
							|en = 'The ""%1"" operation control'; fa = 'The ""%1"" operation control';
							|it = 'Controllo operazione ""%1""';
							|pl = 'Kontrola operacji ""%1""';
							|tr = '""%1"" işleminin kontrolü'"), OperationName_);
	
	If Not Parameters.Property("UnitOfMeasurePresentation", UnitOfMeasurePresentation) Then
		UnitOfMeasurePresentation = ProductionManagementClientServer.PresentationOfUnitOfOperation(
			Undefined,
			FollowUp);
	EndIf;
		
	FillInListOfReasonsForNotPassingControl();
	
	CustomizeFormElements();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Done(Command)
	
	AllocateBalance("QuantityIsReady");
	
EndProcedure

&AtClient
Procedure ForRevision(Command)
	
	AllocateBalance("QuantityForRevision");
	
EndProcedure

&AtClient
Procedure DefectiveGoods(Command)
	
	AllocateBalance("DefectiveGoodsCount");
	
EndProcedure

&AtClient
Procedure Apply(Command)
	
	If CheckAttributesFilling() Then
		
		Result = New Structure;
		Result.Insert("ProtocolEntries", New Array);
		Result.Insert("RecalculateStandards", RecalculateStandards);
		
		If QuantityForRevision > 0 Then
			NewAction = ProductionAccountingClientServer.RecordProtocolConstructor("SendForRevision");
			NewAction.Count  = QuantityForRevision;
			NewAction.Comment = ReasonForRevision;
			Result.ProtocolEntries.Add(NewAction);
		EndIf;
		
		If DefectiveGoodsCount > 0 Then
			NewAction = ProductionAccountingClientServer.RecordProtocolConstructor("DefectiveGoods");
			NewAction.Count  = DefectiveGoodsCount;
			NewAction.Comment = DefectsReason;
			Result.ProtocolEntries.Add(NewAction);
		EndIf;
		
		If QuantityIsReady > 0 Then
			NewAction = ProductionAccountingClientServer.RecordProtocolConstructor("Control");
			NewAction.Count  = QuantityIsReady;
			Result.ProtocolEntries.Add(NewAction);
		EndIf;
		
		Close(Result);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region EventHandlersForFormElements

&AtClient
Procedure CountOnChange(Item)
	
	CalculateAttributeRecalculateStandards(ThisObject);
	
	ConfigureDependentFormElements(ThisObject);
	
EndProcedure

&AtClient
Procedure ReasonOnChange(Item)
	
	ConfigureDependentFormElements(ThisObject);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure CustomizeFormElements()
	
	SetUpMarriageReflectionElements();
	
	SetUpRecalculateStandardsSwitch();
	
	ConfigureDependentFormElements(ThisObject);
	
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureDependentFormElements(Form, AttributesList = "")
	
	Items = Form.Items;
	
	Initialize = IsBlankString(AttributesList);
	AttributesStructure1 = New Structure(AttributesList);
	
	If Initialize
		Or AttributesStructure1.Property("Count") Then
			
		UpdateQuantityToDistribution(Form);
		
		Items.QuantityForRevision.MaxValue = Form.QuantityForRevision + Form.QuantityToDistribution;
		Items.DefectiveGoodsCount.MaxValue        = Form.DefectiveGoodsCount + Form.QuantityToDistribution;
		Items.QuantityIsReady.MaxValue      = Form.QuantityIsReady + Form.QuantityToDistribution;
		
		Items.GroupQuickCommands.Enabled           = Form.QuantityToDistribution > 0;
		Items.FormApply.Enabled = (Form.QuantityIsReady > 0 Or Form.DefectiveGoodsCount > 0 Or Form.QuantityForRevision > 0);
		
	EndIf;
	
	If Initialize
		Or AttributesStructure1.Property("InfoBar") Then
			
			Items.InformationPanelGroup.Visible = ValueIsFilled(Items.InfoBarLabel.Title);
			
	EndIf;
	
EndProcedure

&AtServer
Procedure SetUpMarriageReflectionElements()
	
	Items.DefectiveGoods.Enabled = OperationAsOutputReference;
	Items.DefectiveGoodsGroup.Enabled = OperationAsOutputReference;
	
	If Not OperationAsOutputReference Then
		Items.InfoBarLabel.Title = Documents.ProductionOperation2_2.WarningTextUnavailabilityOfMarriageReflection();
	EndIf;
	
EndProcedure

&AtServer
Procedure SetUpRecalculateStandardsSwitch()
	
	Settings = Documents.ProductionOperation2_2.RecalculateStandardsSwitchSettings(ProductionOperation);
	
	Items.RecalculateStandards.Visible = Settings.Visible;
	Items.RecalculateStandards.Title = Settings.Title;
	
EndProcedure

&AtClientAtServerNoContext
Procedure UpdateQuantityToDistribution(Form)
	
	Form.QuantityToDistribution = Form.FollowUp
		- Form.QuantityForRevision
		- Form.DefectiveGoodsCount
		- Form.QuantityIsReady;
	
EndProcedure

&AtClient
Procedure AllocateBalance(Var_AttributeName)
	
	ThisObject[Var_AttributeName] = ThisObject[Var_AttributeName] + QuantityToDistribution;
	CurrentItem = Items[Var_AttributeName];
	
	CalculateAttributeRecalculateStandards(ThisObject);
	
	ConfigureDependentFormElements(ThisObject);
	
EndProcedure

&AtServer
Procedure FillInListOfReasonsForNotPassingControl()
	
	QueryText = "
	|SELECT TOP 50
	|	Table.Comment AS Comment
	|FROM
	|	Document.ProductionOperation2_2.Protocol AS Table
	|WHERE
	|	Table.Event = VALUE(Enum.RoutingOperationProtocolEvents.SendForRevision)
	|	AND Table.Comment <> """"
	|	AND Table.Ref.Posted
	|ORDER BY
	|	Table.Date DESC
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 50
	|	Table.Comment AS Comment
	|FROM
	|	Document.ProductionOperation2_2.Protocol AS Table
	|WHERE
	|	Table.Event = VALUE(Enum.RoutingOperationProtocolEvents.DefectiveGoods)
	|	AND Table.Comment <> """"
	|	AND Table.Ref.Posted
	|ORDER BY
	|	Table.Date DESC
	|";
	
	Query = New Query(QueryText);
	
	Results = Query.ExecuteBatch();
	
	ListsToFillIn = New Array;
	ListsToFillIn.Add(Items.ReasonForRevision.ChoiceList);
	ListsToFillIn.Add(Items.DefectsReason.ChoiceList);
	
	For IndexOf = 0 To 1 Do
		CurrentList = ListsToFillIn[IndexOf]; // ValueList
		If Not Results[IndexOf].IsEmpty() Then
			Selection = Results[IndexOf].Select();
			While Selection.Next() Do
				If CurrentList.FindByValue(Selection.Comment) = Undefined Then
					CurrentList.Add(Selection.Comment);
					If CurrentList.Count() >= 5 Then
						Break;
					EndIf;
				EndIf;
			EndDo;
		EndIf;
	EndDo;
	
EndProcedure

&AtClient
Function CheckAttributesFilling()
	
	HasErrors = False;
	
	If (QuantityForRevision + DefectiveGoodsCount + QuantityIsReady) > FollowUp Then
		CommonClient.MessageToUser(
			NStr("vi = 'Đã vượt quá số lượng hợp lệ cần kiểm soát';
				|ru = 'Превышено доступное к контролю количество';
				|en = 'The quantity available for control is exceeded'; fa = 'The quantity available for control is exceeded';
				|it = 'Numero disponibile per il controllo superato';
				|pl = 'Przekroczono ilość, dostępną do kontroli';
				|tr = 'Kontrol edilecek mevcut miktar aşıldı'"),,"FollowUp",,HasErrors);
	EndIf;
	
	Return Not HasErrors;
	
EndFunction

&AtClientAtServerNoContext
Procedure CalculateAttributeRecalculateStandards(Form)
	
	If Not Form.Items.RecalculateStandards.Visible Then
		Return;
	EndIf;
	
	If Form.DefectiveGoodsCount Then
		Form.RecalculateStandards = True;
	EndIf;
	
EndProcedure

#EndRegion