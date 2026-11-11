
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	ValueType = Parameters.ValueType;
	AdditionalProperty = Parameters.AdditionalProperty;
	AvailableTypes = Metadata.ChartsOfCharacteristicTypes.BudgetFlowItemDimensions.Type;
	
	FillInTypeTree();
	
EndProcedure

#EndRegion

#Region EventHandlersForFormElements

&AtClient
Procedure TypeTreeCheckOnChange(Item)
	
	CurrentData = Items.TypeTree.CurrentData;
	
	If CurrentData.Check Then
		TreeItems = TypeTree.GetItems();
		Selected_2Type = New Structure;
		Selected_2Type.Insert("Type",                    CurrentData.Type);
		Selected_2Type.Insert("AdditionalProperty", CurrentData.AdditionalProperty);
		IncompatibleTypes = New Array;
		CheckTypeSharingRecursively(TreeItems, Selected_2Type, IncompatibleTypes);
		
		If IncompatibleTypes.Count() = 0 Then
			Return;
		EndIf;
		
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("Selected_2Type",      CurrentData);
		AdditionalParameters.Insert("IncompatibleTypes", IncompatibleTypes);
		CallbackDescription = New CallbackDescription("QuestionDisablingIncompatibleTypes", ThisForm, AdditionalParameters);
		If IncompatibleTypes.Count() = 1 Then
			QueryText = NStr("vi = 'Trước đây đã chọn kiểu không tương thích với kiểu hiện tại. 
				|Để sử dụng kiểu đã chọn, cần tắt kiểu không tương thích. Tắt?';
				|ru = 'Ранее были выбран тип несовместимый с текущим. 
				|Для использования выбранного типа необходимо отключить несовместимый. Отключить?';
				|en = 'The previously selected type is incompatible with the current one.
				|To use the selected type, you should disable the incompatible one. Disable?'; fa = 'The previously selected type is incompatible with the current one.
				|To use the selected type, you should disable the incompatible one. Disable?';
				|it = 'Precedentemente è stato selezionato un tipo non compatibile con quello corrente. 
				| Per l''utilizzo del tipo selezionato è necessario disattivare quello non compatibile. Disattivare?';
				|pl = 'Wcześniej został wybrany typ niezgodny z bieżącym.
				|Aby użyć wybranego typu, należy wyłączyć niezgodny. Wyłączyć?';
				|tr = 'Önceden seçilip mevcut türler ile uyuşmayan bir tür mevcut. 
				|Seçilen türlerin kullanılmaları için uyumsuz olanın devre dışı bırakılması gerekiyor. Devre dışı bırakılsın mı?'");
		Else
			QueryText = NStr("vi = 'Trước đây đã chọn các kiểu không tương thích với kiểu hiện tại. 
				|Để sử dụng kiểu đã chọn, cần tắt kiểu không tương thích. Tắt?';
				|ru = 'Ранее были выбраны типы несовместимые с текущим. 
				|Для использования выбранного типа необходимо отключить несовместимые типы. Отключить?';
				|en = 'The previously selected types are incompatible with the current one.
				|To use the selected type, you should disable the incompatible ones. Disable?'; fa = 'The previously selected types are incompatible with the current one.
				|To use the selected type, you should disable the incompatible ones. Disable?';
				|it = 'Precedentemente erano stati selezionati dei tipi non compatibili con quello corrente. 
				| Per l''utilizzo del tipo selezionato è necessario disattivare quelli non compatibili. Disattivare?';
				|pl = 'Wcześniej zostały wybrane typ niezgodne z bieżącym.
				|Aby użyć wybranego typu, należy wyłączyć niezgodne typy. Wyłączyć?';
				|tr = 'Önceden seçilip mevcut türler ile uyuşmayan türler mevcut. 
				|Seçilen türlerin kullanılmaları için uyumsuz olanın devre dışı bırakılması gerekiyor. Devre dışı bırakılsın mı?'");
		EndIf;
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure TypeTreeOnActivateRow(Item)
		
	CurrentData = Items.TypeTree.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	Parent = CurrentData.GetParent();
	StringToCheck = ?(Parent = Undefined,CurrentData,Parent);
	
	If ContextMenuKind = StringToCheck.TypePresentation Then
		Return;
	EndIf;
	
	ContextMenuKind = StringToCheck.TypePresentation;
	
	AdditionalDetailsLine_ = NStr("vi = 'Mục tin bổ sung';
									|ru = 'Дополнительные реквизиты';
									|en = 'Additional attributes'; fa = 'ویژگی‌های تکمیلی';
									|it = 'Requisiti aggiuntivi';
									|pl = 'Atrybuty dodatkowe';
									|tr = 'Ek öznitelikler'");
	LineAdditionalInformation = NStr("vi = 'Thông tin bổ sung';
									|ru = 'Дополнительные сведения';
									|en = 'Additional information'; fa = 'اطلاعات تکمیلی';
									|it = 'Informazioni aggiuntive';
									|pl = 'Dodatkowego informacje';
									|tr = 'Ek bilgiler'");

	Items.TypeTreeContextMenuCreateProperty.Visible = False;
	Items.TypeTreeContextMenuCreateAdditionalAttribute.Visible = False;

	If StringToCheck.TypePresentation = AdditionalDetailsLine_ Then
		Items.TypeTreeContextMenuCreateAdditionalAttribute.Visible = True;	
	ElsIf StringToCheck.TypePresentation = LineAdditionalInformation Then
		Items.TypeTreeContextMenuCreateProperty.Visible = True;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CreateAdditionalInformation(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("IsAdditionalInfo", True);
	
	Notification = New CallbackDescription("CreatingAdditionalProperty", ThisForm);
	OpenForm("ChartOfCharacteristicTypes.AdditionalAttributesAndInfo.Form.ItemForm", 
		FormParameters, ThisForm, , , , Notification);
	
EndProcedure

&AtClient
Procedure CreateAdditionalAttribute(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("IsAdditionalInfo", False);
	
	Notification = New CallbackDescription("CreatingAdditionalProperty", ThisForm);
	OpenForm("ChartOfCharacteristicTypes.AdditionalAttributesAndInfo.Form.ItemForm", 
		FormParameters, ThisForm, , , , Notification);
	
EndProcedure

&AtClient
Procedure Select(Command)
	
	ValueType = New TypeDescription();
	AdditionalProperty = Undefined;
	
	SelectedTypesRecursively(TypeTree.GetItems());
	
	Result = New Structure;
	Result.Insert("ValueType",            ValueType);
	Result.Insert("AdditionalProperty", AdditionalProperty);
	
	Close(Result);
	
EndProcedure

&AtClient
Procedure EditValues(Command)
	
	CurrentData = Items.TypeTree.CurrentData;
	If CurrentData = Undefined Or CurrentData.Ref = Undefined Then
		Return;
	EndIf;
	
	If ValueIsFilled(CurrentData.AdditionalProperty) Then
		ShowValue(,CurrentData.AdditionalProperty);
	Else
		ListFormName = NameOfListFormByType(CurrentData.Type);
		OpenForm(ListFormName, , ThisForm);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure FillInTypeTree()
	
	TypeTree.GetItems().Clear();
	
	AddPredefinedTypes();
	AddAdditionalProperties();
	
EndProcedure

&AtServer
Procedure AddPredefinedTypes()
	
	UsePartnersAsCounterparties = GetFunctionalOption("UsePartnersAsCounterparties");
	
	StringPredefinedTypes = TypeTree.GetItems().Add();
	StringPredefinedTypes.TypePresentation = NStr("vi = 'Các loại được xác định trước';
													|ru = 'Предопределенные типы';
													|en = 'Predefined types'; fa = 'Predefined types';
													|it = 'Tipi predefiniti';
													|pl = 'Typy predefiniowane';
													|tr = 'Ek türler'");
	
	For Each Type In AvailableTypes.Types() Do
		If Type = Type("CatalogRef.ObjectsPropertiesValues") Then
			Continue;
		EndIf;
		
		If UsePartnersAsCounterparties 
			And Type = Type("CatalogRef.Counterparties") Then
			Continue;
		EndIf;
		
		NewRow = StringPredefinedTypes.GetItems().Add();
		NewRow.Check = ValueType.ContainsType(Type);
		TypesArray = New Array;
		TypesArray.Add(Type);
		NewRow.Type = New TypeDescription(TypesArray);
		NewRow.TypePresentation = Metadata.FindByType(Type).Presentation();
		NewRow.Ref = New (Type);
		
		If NewRow.Check Then
			Items.TypeTree.CurrentRow = NewRow.GetID();
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure AddAdditionalProperties()
	
	AdditionalDetailsLine_ = TypeTree.GetItems().Add();
	AdditionalDetailsLine_.TypePresentation = NStr("vi = 'Mục tin bổ sung';
													|ru = 'Дополнительные реквизиты';
													|en = 'Additional attributes'; fa = 'ویژگی‌های تکمیلی';
													|it = 'Requisiti aggiuntivi';
													|pl = 'Atrybuty dodatkowe';
													|tr = 'Ek öznitelikler'");
	
	LineAdditionalInformation = TypeTree.GetItems().Add();
	LineAdditionalInformation.TypePresentation = NStr("vi = 'Thông tin bổ sung';
														|ru = 'Дополнительные сведения';
														|en = 'Additional information'; fa = 'اطلاعات تکمیلی';
														|it = 'Informazioni aggiuntive';
														|pl = 'Dodatkowego informacje';
														|tr = 'Ek bilgiler'");
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	Properties.Ref AS AdditionalProperty,
	|	Properties.Presentation AS Presentation,
	|	Properties.ValueType,
	|	Properties.IsAdditionalInfo
	|FROM
	|	ChartOfCharacteristicTypes.AdditionalAttributesAndInfo AS Properties
	|
	|ORDER BY
	|	Properties.Ref";
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		Types = Selection.ValueType.Types();
		If Types.Count() > 1 Then
			Continue;
		EndIf;
		
		If Not AvailableTypes.ContainsType(Types[0]) Then
			Continue;
		EndIf;
		
		If Selection.IsAdditionalInfo Then
			NewRow = LineAdditionalInformation.GetItems().Add();
		Else
			NewRow = AdditionalDetailsLine_.GetItems().Add();
		EndIf;
		NewRow.AdditionalProperty = Selection.AdditionalProperty; 
		NewRow.Check = (Selection.AdditionalProperty = AdditionalProperty);
		NewRow.Type = Selection.ValueType;
		NewRow.TypePresentation = Selection.Presentation;
		 
		NewRow.Ref = New (Types[0]);
		
		If NewRow.Check Then
			Items.TypeTree.CurrentRow = NewRow.GetID();
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Function NameOfListFormByType(TypeDescription)
	
	MetadataObject = Metadata.FindByType(TypeDescription.Types()[0]);
	Return MetadataObject.FullName() + ".ListForm";
	
EndFunction

&AtClient
Function SelectedTypesRecursively(TreeItems)
	
	For Each Item In TreeItems Do
		If Item.Check Then
			ValueType = New TypeDescription(ValueType, Item.Type.Types());
			AdditionalProperty = Item.AdditionalProperty;
		EndIf;
		SelectedTypesRecursively(Item.GetItems());
	EndDo;
	
EndFunction

&AtClient
Procedure CheckTypeSharingRecursively(TreeItems, Selected_2Type, IncompatibleTypes) 
	
	For Each TreeItem In TreeItems Do
		
		ThisIsSelectedType = 
			(TreeItem.Type = Selected_2Type.Type 
			And TreeItem.AdditionalProperty = Selected_2Type.AdditionalProperty);
			
		If TreeItem.Check And Not ThisIsSelectedType Then
			// 1. You cannot select an additional property together with other predefined types or additional properties
			// 2. You cannot select a predefined type together with additional properties.
			If ValueIsFilled(Selected_2Type.AdditionalProperty) 
				Or ValueIsFilled(TreeItem.AdditionalProperty) Then
				IncompatibleTypes.Add(TreeItem);
			EndIf;
		EndIf;
		CheckTypeSharingRecursively(TreeItem.GetItems(), Selected_2Type, IncompatibleTypes);
	EndDo;
	
EndProcedure

&AtClient
Procedure QuestionDisablingIncompatibleTypes(Response, AdditionalParameters) Export
	
	If Response = DialogReturnCode.Yes Then
		For Each IncompatibleType In AdditionalParameters.IncompatibleTypes Do
			IncompatibleType.Check = False;
		EndDo;
	Else
		AdditionalParameters.Selected_2Type.Check = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure CreatingAdditionalProperty(Result, AdditionalParameters) Export
	
	FillInTypeTree();
	
EndProcedure

#EndRegion
