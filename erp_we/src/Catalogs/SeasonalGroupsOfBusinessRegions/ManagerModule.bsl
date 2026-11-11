
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Defines the configuration for the initial fill of elements
//
// Parameters:
//  Settings - Structure - filling settings:
//   * OnInitialItemFilling - Boolean - if True,
//      the individual filling procedure will be called for each element at the beginning of the element Filling.
Procedure OnSetUpInitialItemsFilling(Settings) Export
	
	Settings.OnInitialItemFilling = True;
	
EndProcedure

// Called when the directory is initially filled in.
//
// Parameters:
//  LanguagesCodes - Array - list of configuration languages. Relevant for multilingual configurations.
//  Items   - ValueTable - fill-in data. The composition of columns corresponds to the set
//                                 of reference book details.
//  TabularSections - Structure - Key - Name of the table part of the object.
//                               Value-Uploads an empty table part to the table of values.
//
Procedure OnInitialItemsFilling(LanguagesCodes, Items, TabularSections) Export

	#Region OtherItems
	Item = Items.Add();
	Item.PredefinedDataName = "OtherItems";
	Item.Description = "<" + NStr("vi = 'Phần khác';
									|ru = 'Прочие';
									|en = 'Other'; fa = 'سایر';
									|it = 'Altri';
									|pl = 'Other';
									|tr = 'Diğer'", Common.DefaultLanguageCode()) + ">";
	#EndRegion

EndProcedure

// Called when the element being created is initially filled in.
//
// Parameters:
//  Object                  - CatalogObject.SeasonalGroupsOfBusinessRegions - the object to fill in.
//  Data                  - ValueTableRow - fill-in data.
//  AdditionalParameters - Structure - advanced setting.
//
Procedure OnInitialItemFilling(Object, Data, AdditionalParameters) Export
	
	
	
EndProcedure

#EndRegion
#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
Procedure OnAddUpdateHandlers(Handlers) Export

	Handler = Handlers.Add();
	Handler.Procedure = "Catalogs.SeasonalGroupsOfBusinessRegions.FillItemsWithInitialData";
	Handler.Version = "11.5.5.51";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("db063bfe-d678-45c8-917a-50f4f47d2846");
	Handler.UpdateDataFillingProcedure = "Catalogs.SeasonalGroupsOfBusinessRegions.RegisterPredefinedItemsToUpdate";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Comment = NStr("vi = 'Cập nhật tên gọi phần tử định trước.
	|Trước khi kết thúc xử lý tên gọi các phần tử này, trong nhiều trường hợp sẽ phản ánh không chính xác.';
	|ru = 'Обновление наименований предопределенных элементов.
	|До завершения обработки наименования этих элементов в ряде случаев будет отображаться некорректно.';
	|en = 'Updates the names of predefined items.
	|While the update is in progress, names of predefined items might be displayed incorrectly.'; fa = 'Updates the names of predefined items.
	|While the update is in progress, names of predefined items might be displayed incorrectly.';
	|it = 'Aggiornamento dei nomi degli elementi predefiniti.
	|Fino al completamento dell''elaborazione, in alcuni casi i nomi di questi elementi verranno visualizzati in modo errato.';
	|pl = 'Aktualizacja nazw elementów predefiniowanych.
	|W celu zakończenia przetwarzania nazwa tych elementów w szeregu przypadków będą odzwierciedlane błędnie.';
	|tr = 'Önceden tanımlanmış öğe adlarının güncellenmesi.
	|Güncelleme sürerken önceden tanımlanmış öğelerin adları yanlış görüntülenebilir.'");
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.Catalogs.SeasonalGroupsOfBusinessRegions.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.Catalogs.SeasonalGroupsOfBusinessRegions.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	ToLock = New Array;
	ToLock.Add(Metadata.Catalogs.SeasonalGroupsOfBusinessRegions.FullName());
	Handler.ObjectsToLock = StrConcat(ToLock, ",");

EndProcedure

Procedure RegisterPredefinedItemsToUpdate(Parameters) Export
	
	InfobaseUpdate.RegisterPredefinedItemsToUpdate(Parameters, Metadata.Catalogs.SeasonalGroupsOfBusinessRegions);
	
EndProcedure

Procedure FillItemsWithInitialData(Parameters) Export
	
	PopulationSettings = InfobaseUpdate.PopulationSettings();
	PopulationSettings.Attributes = "Description";
	
	InfobaseUpdate.FillItemsWithInitialData(Parameters, Metadata.Catalogs.SeasonalGroupsOfBusinessRegions, PopulationSettings);
	
EndProcedure

#EndRegion


#EndIf
