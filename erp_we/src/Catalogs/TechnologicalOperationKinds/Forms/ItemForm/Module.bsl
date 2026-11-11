
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	InsertRight1 = AccessRight("Insert", Metadata.ChartsOfCharacteristicTypes.AdditionalAttributesAndInfo);
	Items.SetUpBankingDetails.Visible = InsertRight1;
	Items.ToConfigureTheDetails.Visible = InsertRight1;
	
	If Object.Ref.IsEmpty() Then
		
		OnReadCreateAtServer();
		
	EndIf;
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	OnReadCreateAtServer();
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_AdditionalAttributesAndInfoSets"
		Or EventName = "Write_AdditionalAttributesAndInfo" Then
		
		ReadProperties_();
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersAddAttributes

&AtClient
Procedure AddAttributesSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	ShowValue(, Items.AddAttributes.CurrentData.Property);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersAddAttributes

&AtClient
Procedure AddPropertiesSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	ShowValue(, Items.AddProperties.CurrentData.Property);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SetUpBankingDetails(Command)
	
	PropertyKind = PredefinedValue("Enum.PropertiesKinds.AdditionalAttributes");
	
	If Object.Ref.IsEmpty() Then
		
		CallbackDescription = New CallbackDescription(
			"WriteAndOpenPropertiesViewForm",
			ThisForm,
			New Structure("PropertyKind", PropertyKind));
			
		QueryText = NStr("vi = 'Chỉ có thể thay đổi các mục tin sau khi ghi lại đối tượng.
			|Ghi lại và tiếp tục?';
			|ru = 'Изменение реквизитов возможно только после записи объекта.
			|Записать и продолжить?';
			|en = 'You can change attributes only after recording the item.
			|Record and continue?'; fa = 'You can change attributes only after recording the item.
			|Record and continue?';
			|it = 'La modifica dei requisiti è possibile solo dopo la scrittura dell''oggetto.
			|Scriverlo e continuare?';
			|pl = 'Zmiana atrybutów jest możliwa tylko po zapisaniu obiektu. 
			| Zapisać i kontynuować?';
			|tr = 'Özniteliklerin değiştirilmesi ancak nesne kaydedildikten sonra mümkündür.
			|Kaydedilsin ve devam edilsin mi?'");
		
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
		
	Else
		
		OpenPropertiesViewForm(PropertyKind);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ToConfigureTheDetails(Command)
	
	PropertyKind = PredefinedValue("Enum.PropertiesKinds.AdditionalInfo");
	
	If Object.Ref.IsEmpty() Then
		
		CallbackDescription = New CallbackDescription(
			"WriteAndOpenPropertiesViewForm",
			ThisForm,
			New Structure("PropertyKind", PropertyKind));
			
		QueryText = NStr("vi = 'Chỉ có thể thay đổi các thông tin sau khi ghi lại đối tượng.
			|Ghi lại và tiếp tục?';
			|ru = 'Изменение сведений возможно только после записи объекта.
			|Записать и продолжить?';
			|en = 'You can change the information only after recording the item.
			|Record and continue?'; fa = 'You can change the information only after recording the item.
			|Record and continue?';
			|it = 'La modifica dei requisiti è possibile solo dopo la scrittura dell''oggetto.
			|Scriverlo e continuare?';
			|pl = 'Zmiana informacji jest możliwa tylko po zapisaniu obiektu. 
			| Zapisać i kontynuować?';
			|tr = 'Bilgi kaydının değiştirilmesi ancak nesne kaydedildikten sonra mümkündür.
			|Kaydedilsin ve devam edilsin mi?'");
		
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
		
	Else
		
		OpenPropertiesViewForm(PropertyKind);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure WriteAndOpenPropertiesViewForm(QuestionResult, Var_Parameters) Export

	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	If Write() Then
		
		OpenPropertiesViewForm(Var_Parameters.PropertyKind);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure OnReadCreateAtServer()
	
	ReadProperties_();
	
EndProcedure

&AtServer
Procedure ReadProperties_()
	
	If Object.Ref.IsEmpty() Then
		Return;
	EndIf;
	
	TempTablesManager = New TempTablesManager;
	
	Catalogs.TechnologicalOperationKinds.CreateTTSetProperties(
		Object.Ref,
		TempTablesManager,
		True,
		True);
		
	Query = New Query(
		"SELECT
		|	TTSetProperties.Property  AS Property,
		|	TTSetProperties.Title AS Title,
		|	3                          AS PictureNumber
		|FROM
		|	TTSetProperties AS TTSetProperties
		|WHERE
		|	NOT TTSetProperties.IsAdditionalInfo
		|	AND NOT TTSetProperties.DeletionMark
		|
		|ORDER BY
		|	TTSetProperties.LineNumber
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TTSetProperties.Property  AS Property,
		|	TTSetProperties.Title AS Title,
		|	3                          AS PictureNumber
		|FROM
		|	TTSetProperties AS TTSetProperties
		|WHERE
		|	TTSetProperties.IsAdditionalInfo
		|	AND NOT TTSetProperties.DeletionMark
		|
		|ORDER BY
		|	TTSetProperties.LineNumber");
	Query.TempTablesManager = TempTablesManager;
	
	ResultsArray = Query.ExecuteBatch();
	
	AddAttributes.Load(ResultsArray[0].Unload());
	AdditionalAttributesQuantity = AddAttributes.Count();
	
	AddProperties.Load(ResultsArray[1].Unload());
	AddInformationQuantity = AddProperties.Count();
	
EndProcedure

&AtClient
Procedure OpenPropertiesViewForm(PropertyKind)
	
	FormParameters = New Structure;
	FormParameters.Insert("CurrentRow", Object.PropertiesSet);
	FormParameters.Insert("PropertyKind", PropertyKind);
	
	OpenForm(
		"Catalog.AdditionalAttributesAndInfoSets.ListForm",
		FormParameters,
		ThisObject,
		UUID);
	
EndProcedure

#EndRegion

