
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	DimensionKind = Parameters.DimensionKind;
	AddressOfDataCompositionSchema = Parameters.AddressOfDataCompositionSchema;
	CurrentExpression = Parameters.CurrentExpression;
	PeriodOfShift = Parameters.PeriodOfShift;
	
	Attributes = New Structure;
	Attributes.Insert("ValueType", "ValueType");
	Attributes.Insert("AdditionalProperty", "AdditionalProperty");
	Attributes.Insert("IsAdditionalInfo", "AdditionalProperty.IsAdditionalInfo");
	ValuesOfAnalyticsTypeDetails = Common.ObjectAttributesValues(DimensionKind, Attributes);
	FillPropertyValues(ThisObject, ValuesOfAnalyticsTypeDetails);
	If Not ValueIsFilled(DimensionKind) Then
		ValueType = New TypeDescription(CommonClientServer.ValueInArray(TypeOf(PeriodOfShift)));
	EndIf;
	FillInAdditionalPropertyID();
	
	CommandVisibility = ValueIsFilled(AdditionalProperty);
	Items.FormAddAdditionalProperty.Visible = CommandVisibility;
	Items.SelectionTreeContextMenuAddAdditionalProperty.Visible = CommandVisibility;
	If CommandVisibility Then
		If IsAdditionalInfo Then
			CommandTitle = NStr("vi = 'Thêm thông tin bổ sung';
								|ru = 'Добавить дополнительное сведение';
								|en = 'Add additional information'; fa = 'Add additional information';
								|it = 'Aggiungere informazioni aggiuntive';
								|pl = 'Dodaj informację dodatkową';
								|tr = 'Ek bilgi kaydı ekle'");
		Else
			CommandTitle = NStr("vi = 'Thêm mục tin bổ sung';
								|ru = 'Добавить дополнительный реквизит';
								|en = 'Add additional attribute'; fa = 'Add additional attribute';
								|it = 'Aggiungere requisito aggiuntivo';
								|pl = 'Dodaj atrybut dodatkowy';
								|tr = 'Ek öznitelik ekle'");
		EndIf;
		Items.FormAddAdditionalProperty.Title = CommandTitle;
		Items.SelectionTreeContextMenuAddAdditionalProperty.Title = CommandTitle;
	EndIf;
	
	DescriptionOfTypesAndProperties = Metadata.ChartsOfCharacteristicTypes.AdditionalAttributesAndInfo.Type;
	TypeOfAnalyticsCanBeDefinedUsingThisProperty = False;
	If ValueType.Types().Count() = 1 And DescriptionOfTypesAndProperties.ContainsType(ValueType.Types()[0]) Then
		TypeOfAnalyticsCanBeDefinedUsingThisProperty = True;
	EndIf;
	
	CommandVisibility = Not ValueIsFilled(AdditionalProperty) And TypeOfAnalyticsCanBeDefinedUsingThisProperty;
	
	Items.FormCreateAdditionalAttribute.Visible = CommandVisibility;
	Items.FormCreateAdditionalInformation.Visible = CommandVisibility;
	Items.SelectionTreeContextMenuCreateAdditionalInformation.Visible = CommandVisibility;
	Items.SelectionTreeContextMenuCreateAdditionalAttribute.Visible = CommandVisibility;
	
	MaximumRowExpansionLevel = 2;
	FinancialReportingServer.FillInAvailableFieldsAccordingToDataLayoutScheme(ThisForm);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Select(Command)
	
	ProcessSelection(Items.SelectionTree.CurrentRow);
	
EndProcedure

&AtClient
Procedure AddAdditionalProperty(Command)
	
	CurrentData = Items.SelectionTree.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	CurrentExpression = CurrentData.FullRowID;
	
	AddAdditionalPropertyServer(AdditionalProperty, CurrentData.ValueType)
	
EndProcedure

&AtClient
Procedure CreateAdditionalInformation(Command)
	
	CurrentData = Items.SelectionTree.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	CurrentExpression = CurrentData.FullRowID;
	
	CreateAdditionalClientProperty(CurrentData.ValueType, True);
	
EndProcedure

&AtClient
Procedure CreateAdditionalAttribute(Command)
	
	CurrentData = Items.SelectionTree.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	CurrentExpression = CurrentData.FullRowID;
	
	CreateAdditionalClientProperty(CurrentData.ValueType);
	
EndProcedure

#EndRegion

#Region EventHandlersForFormElements

&AtClient
Procedure SelectionTreeOnActivateRow(Item)
	
	CommandAvailability = False;
	
	CurrentData = Items.SelectionTree.CurrentData;
	If CurrentData <> Undefined Then
		CurrentExpression = CurrentData.FullRowID;
		// The field is of reference type and does not exceed the maximum scan level.
		CommandAvailability = (CurrentData.ExpandToAttributes);
	EndIf;
	
	Items.FormCreateAdditionalAttribute.Enabled = CommandAvailability;
	Items.FormCreateAdditionalInformation.Enabled = CommandAvailability;
	Items.FormAddAdditionalProperty.Enabled = CommandAvailability;
	Items.SelectionTreeContextMenuCreateAdditionalInformation.Enabled = CommandAvailability;
	Items.SelectionTreeContextMenuAddAdditionalProperty.Enabled = CommandAvailability;
	Items.SelectionTreeContextMenuCreateAdditionalAttribute.Enabled = CommandAvailability; 
	
EndProcedure

&AtClient
Procedure SelectionTreeBeforeExpand(Item, String, Cancel)
	
	CurrentData = SelectionTree.FindByID(String);
	If CurrentData.ExpandToAttributes
		And Not CurrentData.SubordinateRowsExpanded Then
		// If there are subordinate details and the details of the next level have not been received for them.
		ExpandSubordinateRowsOfOperandTree(String);
	EndIf;
	
EndProcedure

&AtServer
Procedure ExpandSubordinateRowsOfOperandTree(IDOfCurRowOfOperandTree)
	
	ProcessingOfFormulas.ExpandOperandStringOfFormTree(SelectionTree,
		IDOfCurRowOfOperandTree,
		MaximumRowExpansionLevel);
	
	// Processing restrictions by value type or identifier add.the props on the form.
	CurrentData = SelectionTree.FindByID(IDOfCurRowOfOperandTree);
	For Each AddedRow In CurrentData.GetItems() Do
		If AddedRow.OperandSelectionAllowed Then
			AddedRow.OperandSelectionAllowed = FinancialReportingServer.SuitableSelectionField(AddedRow,
				ValueType, AdditionalPropertyID);
		EndIf;
	EndDo;
	
	
EndProcedure

&AtClient
Procedure SelectionTreeSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	ProcessSelection(RowSelected);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure DeleteDisallowedCharacters(String) Export
	InvalidChars = """'`/\[]{}:;|-=?*<>,.()+#№@!%^&~";
	String = StrConcat(StrSplit(String, InvalidChars, True));
EndProcedure

&AtClient
Procedure ProcessSelection(RowSelected)
	
	If RowSelected = Undefined Then
		Return;
	EndIf;
	
	TreeRow = SelectionTree.FindByID(RowSelected);
	If Not TreeRow.OperandSelectionAllowed Then
		Return;
	EndIf;
	
	NotifyChoice(TreeRow.FullRowID);
	
EndProcedure

&AtClient
Procedure CreateAdditionalClientProperty(TypeOfSourceFieldValue, AdditionalInfoItem = False)
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("AdditionalInfoItem", AdditionalInfoItem);
	AdditionalParameters.Insert("TypeOfSourceFieldValue", TypeOfSourceFieldValue);
	
	CallbackDescription = New CallbackDescription("WhenEnteringNameOfAdditionalProperty", ThisObject, AdditionalParameters);
	MessageText = NStr("vi = 'Nhập tên';
						|ru = 'Введите наименование';
						|en = 'Enter name'; fa = 'Enter name';
						|it = 'Inserire denominazione';
						|pl = 'Wprowadź nazwę';
						|tr = 'Tanım giriniz'");
	ShowInputString(CallbackDescription, , MessageText, 150);
	
EndProcedure

&AtClient
Procedure WhenEnteringNameOfAdditionalProperty(Description, AdditionalParameters) Export
	
	If IsBlankString(Description) Then
		MessageText = NStr("vi = 'Nhập tên của mục tin';
							|ru = 'Введите наименование реквизита';
							|en = 'Enter attribute description'; fa = 'Enter attribute description';
							|it = 'Inserire denominazione requisito';
							|pl = 'Wprowadź nazwę atrybutu';
							|tr = 'Özniteliğin tanımını giriniz'");
		CommonClient.MessageToUser(MessageText);
		Return;
	EndIf;
	
	CreateAdditionalServerProperty(Description, 
		AdditionalParameters.TypeOfSourceFieldValue,
		AdditionalParameters.AdditionalInfoItem);
	
EndProcedure

&AtServer
Procedure CreateAdditionalServerProperty(Description, TypeOfSourceFieldValue, IsAdditionalInfo)
	
	LastCreatedProperty = Undefined;
	
	For Each Type In TypeOfSourceFieldValue.Types() Do
		
		Ref = New (Type);
		PropertiesSet = CheckIfAdditionalPropertyCanBeAdded(Ref, IsAdditionalInfo);
		If PropertiesSet = Undefined Then
			Continue;
		EndIf;
		
		BeginTransaction();
		Try
			NewAdditionalProperty = ChartsOfCharacteristicTypes.AdditionalAttributesAndInfo.CreateItem();
			NewAdditionalProperty.PropertiesSet = PropertiesSet;
			NewAdditionalProperty.Title = Description;
			NewAdditionalProperty.Description = Description;
			NewAdditionalProperty.ValueType = ValueType;
			NewAdditionalProperty.IsAdditionalInfo = IsAdditionalInfo;
			
			ObjectTitle = Description;
			DeleteDisallowedCharacters(ObjectTitle);
			ObjectTitleInParts = StrSplit(ObjectTitle, " ", False);
			Name = "";
			For Each TitlePart In ObjectTitleInParts Do
				Name = Name + Upper(Left(TitlePart, 1)) + Mid(TitlePart, 2);
			EndDo;
			UID = New UUID();
			UIDString = StrReplace(String(UID), "-", "");
			NewAdditionalProperty.Name = Name + "_" + UIDString;
			
			NewAdditionalProperty.Write();
			
			AddAdditionalPropertyForObject(PropertiesSet, NewAdditionalProperty.Ref, IsAdditionalInfo); 
			
			LastCreatedProperty = NewAdditionalProperty.Ref;
			
			CommitTransaction();
		Except
			RollbackTransaction();
			Raise;
		EndTry;
		
	EndDo;
	
	If ValueIsFilled(LastCreatedProperty) Then
		CurrentExpression = CurrentExpression + "." + IDOfAdditionalPropsInFormulaLanguage(LastCreatedProperty);
	EndIf;
	
	FinancialReportingServer.FillInAvailableFieldsAccordingToDataLayoutScheme(ThisForm);
	
EndProcedure

&AtServer
Function ObjectPropertySet(Ref)
	
	PropertiesSets = PropertyManagerInternal.GetObjectPropertySets(Ref);
	
	If PropertiesSets.Count() = 0 Then
		Return Undefined;
	Else
		Return PropertiesSets[0].Set;
	EndIf;
	
EndFunction

&AtServer
Procedure AddAdditionalPropertyServer(SelectedAdditionalProperty, TypeDescription)
	
	IsAdditionalInfo = Common.ObjectAttributeValue(
				SelectedAdditionalProperty, "IsAdditionalInfo");
	
	For Each Type In TypeDescription.Types() Do
		Ref = New (Type);
		PropertiesSet = CheckIfAdditionalPropertyCanBeAdded(Ref, IsAdditionalInfo);
		If PropertiesSet = Undefined Then
			Continue;
		EndIf;
		AddAdditionalPropertyForObject(PropertiesSet, SelectedAdditionalProperty, IsAdditionalInfo);
	EndDo;
	
	FinancialReportingServer.FillInAvailableFieldsAccordingToDataLayoutScheme(ThisForm);
	
EndProcedure

&AtServer
Procedure AddAdditionalPropertyForObject(PropertiesSet, SelectedAdditionalProperty, IsAdditionalInfo)
	
	PropertySetObject = PropertiesSet.GetObject(); // CatalogObject.AdditionalAttributesAndInfoSets - 
	If IsAdditionalInfo Then
		AdditionalProperties = PropertySetObject.AdditionalInfo; // TabularSection -
	Else
		AdditionalProperties = PropertySetObject.AdditionalAttributes; // TabularSection -
	EndIf;
	
	NewProperty = AdditionalProperties.Add(); // LineOfATabularSection -
	NewProperty.Property = SelectedAdditionalProperty;
	
	PropertySetObject.Write();
	
EndProcedure

&AtServer
Function CheckIfAdditionalPropertyCanBeAdded(Ref, IsAdditionalInfo)
	
	YouCanAddAdditionalProperty = True;
	If IsAdditionalInfo Then
		If Not PropertyManager.UseAddlInfo(Ref) Then
			YouCanAddAdditionalProperty = False;
			MessageTemplate = NStr("vi = 'Đối tượng ""%1"" không có ý định sử dụng thông tin bổ sung.';
									|ru = 'Для объекта ""%1"" не предусмотрено использование дополнительных сведений.';
									|en = 'Usage of additional information is not provided for the ""%1"" object.'; fa = 'Usage of additional information is not provided for the ""%1"" object.';
									|it = 'Per l''oggetto ""%1"" non è previsto l''utilizzo di informazioni aggiuntive.';
									|pl = 'Dla obiektu ""%1"" nie przewidziano wykorzystywania informacji dodatkowych.';
									|tr = '""%1"" nesnesi için ek bilgi kaydının kullanımı sağlanamadı.'");
		EndIf;
	Else
		If Not PropertyManager.UseAddlAttributes(Ref) Then
			YouCanAddAdditionalProperty = False;
			MessageTemplate = NStr("vi = 'Đối với đối tượng ""%1"", việc sử dụng các chi tiết bổ sung không được cung cấp.';
									|ru = 'Для объекта ""%1"" не предусмотрено использование дополнительных реквизитов.';
									|en = 'Usage of additional attributes is not provided for the ""%1"" object.'; fa = 'Usage of additional attributes is not provided for the ""%1"" object.';
									|it = 'Per l''oggetto ""%1"" non è previsto l''utilizzo di requisiti aggiuntivi.';
									|pl = 'Dla obiektu ""%1"" nie przewidziano wykorzystywania atrybutów dodatkowych.';
									|tr = '""%1"" nesnesi için ek özniteliklerin kullanımı sağlanamadı.'");
		EndIf;
	EndIf;
		
	If Not YouCanAddAdditionalProperty Then
		Common.MessageToUser(
			StringFunctionsClientServer.SubstituteParametersToString(
				MessageTemplate, Ref.Metadata().Presentation()));
		Return Undefined;
	EndIf;
	
	ObjectPropertySet = ObjectPropertySet(Ref);
	
	Return ObjectPropertySet;
	
EndFunction

&AtServer
Function IDOfAdditionalPropsInFormulaLanguage(AdditionalProperty)
	
	Id = "";
	MetadataOfCharacteristics = Metadata.ChartsOfCharacteristicTypes.AdditionalAttributesAndInfo;
	IdentifierExpression = ProcessingOfFormulas.ExpressionOfFullFeatureID(MetadataOfCharacteristics, False);
	IdentifierExpression = StrReplace(IdentifierExpression, "%TableName%", "AdditionalAttributesAndInfo");
	Query = New Query;
	Text =
	"SELECT
	|	&ExpressionOfCharacteristicID AS AdditionalPropertyID
	|FROM
	|	ChartOfCharacteristicTypes.AdditionalAttributesAndInfo AS AdditionalAttributesAndInfo
	|WHERE
	|	AdditionalAttributesAndInfo.Ref = &AdditionalProperty";
	Text = StrReplace(Text, "&ExpressionOfCharacteristicID", IdentifierExpression);
	Query.Text = Text;
	Query.SetParameter("AdditionalProperty", AdditionalProperty);
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		Id = Selection.AdditionalPropertyID;
	EndDo;
	
	Return Id;
EndFunction

&AtServer
Procedure FillInAdditionalPropertyID()
	If ValueIsFilled(AdditionalProperty) Then
		AdditionalPropertyID = IDOfAdditionalPropsInFormulaLanguage(AdditionalProperty);
	Else
		AdditionalPropertyID = "";
	EndIf;
EndProcedure

#EndRegion