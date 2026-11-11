
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	UseQuantity = Parameters.UseQuantity;
	ProductKind = Parameters.ProductKind;
	
	NumberOfSeriesToFillIn = Parameters.SeriesCount;
	
	If UseQuantity Then
		Items.GroupInEachSeries.Visible = True;
		UnitOfMeasurePage = Parameters.UnitOfMeasurePage;
		Items.DifferentQuantityInEachSeries.ChoiceList[0].Presentation = Items.DifferentQuantityInEachSeries.ChoiceList[0].Presentation + " " + UnitOfMeasurePage;
		InEachSeries = Parameters.InEachSeries;
		Items.GroupNumberInEach.Enabled = (InEachSeries = 1);
		CurrentItem = ?(InEachSeries = 1, Items.InEachSeriesQuantity, Items.SeriesCount);
	Else
		SeriesCount = Parameters.SeriesCount;
		Items.GroupInEachSeries.Visible = False;
		CurrentItem = Items.SeriesCount;
	EndIf;	
	
	ManagingElements(ThisForm);
	
	ObjectSeries = Catalogs.ItemsBatches.CreateItem();
	ObjectSeries.ProductKind = ProductKind;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", ObjectSeries);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	PropertyManager.OnCreateAtServer(ThisForm, AdditionalParameters);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure InEachSeriesOnChange(Item)
	
	ManagingElements(ThisForm);
	
EndProcedure

&AtClient
Procedure DifferentQuantityInEachSeriesOnChange(Item)
	
	ManagingElements(ThisForm);
	
EndProcedure

&AtClient
Procedure MethodOfNumberingTheSeriesWhenChanging(Item)
	
	ManagingElements(ThisForm);
	
EndProcedure

&AtClient
Procedure FillInWithAllNumbersFromTheRangeOnChange(Item)
	
	ManagingElements(ThisForm);
	
EndProcedure

&AtClient
Procedure GenerationInOrderOnChange(Item)
	
	ManagingElements(ThisForm);
	
EndProcedure

&AtClient
Procedure GenerationFromARangeOfOnChange(Item)
	
	ManagingElements(ThisForm);
	
EndProcedure

&AtClient
Procedure InEachSeriesQuantityOnChange(Item)
	
	If SeriesNumberingMethod = 0 And NumberOfSeriesToFillIn <> 0 And InEachSeriesQuantity <> 0 Then
		 SeriesCount = NumberOfSeriesToFillIn / InEachSeriesQuantity;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	
	ClearMessages();
	
	If (SeriesNumberingMethod = 1 Or NumberGenerationRestriction = 1)
	 And (EndNumber < InitialNumber Or InitialNumber = 0 Or EndNumber = 0) Then
		CommonClientServer.MessageToUser(NStr("vi = 'Đã đặt sai khoảng số sê-ri.';
												|ru = 'Неверно задан диапазон номеров серий.';
												|en = 'Batch number range is specified incorrectly.'; fa = 'Batch number range is specified incorrectly.';
												|it = 'Intervallo errato di numeri seriali.';
												|pl = 'Został nieprawidłowo ustawiony zakres numerów serii.';
												|tr = 'Parti numarası aralığı doğru ayarlanmadı.'"),, "InitialNumber");
		Return;
	EndIf;
	
	If SeriesNumberingMethod = 0 And Not ValueIsFilled(SeriesCount) Then
		CommonClientServer.MessageToUser(NStr("vi = 'Chưa chỉ ra số lượng sê-ri.';
												|ru = 'Не указано количество серий.';
												|en = 'Batch quantity is not specified.'; fa = 'Batch quantity is not specified.';
												|it = 'Numero di serie non specificato.';
												|pl = 'Nie podano ilości serii.';
												|tr = 'Parti miktarı belirtilmedi.'"),, "SeriesCount");
		Return;
	EndIf;
	
	If SeriesNumberingMethod = 0 And NumberGenerationRestriction = 1
	 And SeriesCount > (EndNumber - InitialNumber + 1) Then
		CommonClientServer.MessageToUser(NStr("vi = 'Số lượng số thứ tự sê-ri vượt quá phạm vi khoảng.';
												|ru = 'Количество номеров серий превышает размер диапазона.';
												|en = 'Quantity of batch numbers exceeds the range size.'; fa = 'Quantity of batch numbers exceeds the range size.';
												|it = 'Numero di articoli non specificato nella serie.';
												|pl = 'Ilość numerów serii przekracza rozmiar zakresu.';
												|tr = 'Parti numaralarının sayısı aralık boyutunu aşıyor.'"),, "SeriesCount");
		Return;
	EndIf;
	
	If UseQuantity And InEachSeries = 1 And Not ValueIsFilled(InEachSeriesQuantity) Then
		CommonClientServer.MessageToUser(NStr("vi = 'Chưa chỉ ra số lượng mặt hàng trong sê-ri.';
												|ru = 'Не указано количество номенклатуры в серии.';
												|en = 'Number of items in batch is not specified.'; fa = 'Number of items in batch is not specified.';
												|it = 'Numero di articoli nella serie non è specificato.';
												|pl = 'Nie podano liczbę nomenklatury w serii.';
												|tr = 'Partideki öğe sayısı belirtilmedi.'"),, "InEachSeriesQuantity");
		Return;
	EndIf;
	
	ReturnStructure = New Structure("
		|SeriesNumberingMethod,
		|SeriesCount,
		|InitialNumber,
		|EndNumber,
		|NumberGenerationRestriction,
		|InEachSeries");
	FillPropertyValues(ReturnStructure, ThisForm);
	
	If Items.GroupInEachSeries.Visible Then
		ReturnStructure.Insert("InEachSeriesQuantity", InEachSeriesQuantity);
	Else 
		ReturnStructure.Insert("InEachSeriesQuantity", 1);
	EndIf;	
	
	GetAdditionalBankingDetails_(ReturnStructure);
	
	Close(ReturnStructure);
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	Close();
EndProcedure

#EndRegion

#Region Private

// StandardSubsystems.Properties

&AtClient
Procedure UpdateAdditionalAttributesDependencies()
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject, ThisObject);
EndProcedure

&AtClient
Procedure Attachable_OnChangeAdditionalAttribute(Item)
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject, ThisObject);
EndProcedure

// End StandardSubsystems.Properties

&AtClientAtServerNoContext
Procedure ManagingElements(Form)
	
	Form.Items.GroupNumberOfEpisodes.Enabled = (Form.SeriesNumberingMethod = 0);
	Form.Items.GenerationSettingsGroup.Enabled = (Form.SeriesNumberingMethod = 0);
	Form.Items.GroupNumberRange.Enabled = (Form.SeriesNumberingMethod = 1);
	Form.Items.GroupNumberRange2.Enabled = (Form.NumberGenerationRestriction = 1);
	
	Form.Items.GroupNumberInEach.Enabled = (Form.InEachSeries = 1);
	
EndProcedure

&AtServer
Procedure GetAdditionalBankingDetails_(ReturnStructure)
	
	ObjectSeries = Catalogs.ItemsBatches.CreateItem();
	PropertyManager.BeforeWriteAtServer(ThisForm, ObjectSeries);
	
	AdditionalAttributes = New Array;
	For Each CurrRow In ObjectSeries.AdditionalAttributes Do
		AdditionalAttributes.Add(
			New FixedStructure("Property, Value, TextString", CurrRow.Property, CurrRow.Value, CurrRow.TextString));
	EndDo;
	
	ReturnStructure.Insert("AdditionalAttributes", New FixedArray(AdditionalAttributes));
	
EndProcedure

// StandardSubsystems.Properties
&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure
// End StandardSubsystems.Properties

#EndRegion
