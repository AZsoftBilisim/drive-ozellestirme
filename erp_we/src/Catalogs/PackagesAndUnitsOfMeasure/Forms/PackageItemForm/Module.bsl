#Region Variables

&AtClient
Var CachedValues; //used by the mechanism for processing changes in PM details

&AtClient
Var RecordingIsInProgress;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	ObjectAttributesLock.LockAttributes(ThisObject);
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
	EndIf;
	
	// StandardSubsystems.Core
	NationalLanguageSupportServer.OnCreateAtServer(ThisObject, Object);
	// End StandardSubsystems.Core
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	OnReadCreateAtServer();
	
	// StandardSubsystems.Core
	NationalLanguageSupportServer.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Core
	
	ConfigurationModificationOverridable.OnReadAtServer(ThisObject, CurrentObject);

EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	CurrentObject.AdditionalProperties.Insert("ParentChangeIsAllowed");
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisObject, Cancel, CurrentObject, WriteParameters);
	
	// StandardSubsystems.Core
	NationalLanguageSupportServer.BeforeWriteAtServer(CurrentObject);
	// End StandardSubsystems.Core
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_ProductPackages", WriteParameters, Object.Ref);
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	If Object.Denominator <> 0 
		And Object.PackageType <> PredefinedValue("Enum.TypesOfItemsPackages.CargoItem")
		And Object.Numerator / Object.Denominator = 1
		And (Modified
			Or (Not ValueIsFilled(Object.Ref)))  Then 
		If Not ThereIsUnitPackageWithUnitOfMeasurement(Object.Ref, Object.Owner, Object.UnitOfMeasure) 
			And Not RecordingIsInProgress Then
			
			If TypeOf(Object.Owner) = Type("CatalogRef.Products") Then
				MessageText = NStr("vi = 'Đối với mặt hàng ""%Owner%"", đã tạo một bộ đóng gói với hệ số 1 và đơn vị tính ""%UnitOfMeasure%"".';
									|ru = 'Для номенклатуры ""%Owner%"" уже создана упаковка с коэффициентом 1 и единицей измерения ""%UnitOfMeasure%"".';
									|en = 'The item ""%Owner%"" already has a packaging unit measured in %UnitOfMeasure% with the 1:1 ratio.'; fa = 'The item ""%Owner%"" already has a packaging unit measured in %UnitOfMeasure% with the 1:1 ratio.';
									|it = 'Per l''articolo ""%Owner%"" è stato già creato l''imballaggio a coefficiente 1 e con unità di misura ""%UnitOfMeasure%"".';
									|pl = 'Dla towaru ""%Owner%"" utworzono już opakowanie ze współczynnikiem 1 i jednostką miary ""%UnitOfMeasure%"".';
									|tr = '""%Owner%"" öğesi için katsayısı 1 ve ölçü birimi ""%UnitOfMeasure%"" olan paketleme ünitesi oluşturuldu.'");
			Else
				MessageText = NStr("vi = 'Đối với một nhóm bộ đóng gói ""%Owner%"", đã tạo một bộ đóng gói với hệ số 1 và đơn vị tính ""%UnitOfMeasure%"".?';
									|ru = 'Для набора упаковок ""%Owner%"" уже создана упаковка с коэффициентом 1 и единицей измерения ""%UnitOfMeasure%"".?';
									|en = 'The packaging group ""%Owner%"" already has a packaging unit measured in %UnitOfMeasure% with the 1:1 ratio.'; fa = 'The packaging group ""%Owner%"" already has a packaging unit measured in %UnitOfMeasure% with the 1:1 ratio.';
									|it = 'Per il kit di imballaggi ""%Owner%"" è stato già creato l''imballaggio a coefficiente 1 e con unità di misura ""%UnitOfMeasure%"".?';
									|pl = 'Dla zestawu opakowań ""%Owner%"" utworzono już opakowanie ze współczynnikiem 1 i jednostką miary ""%UnitOfMeasure%"".?';
									|tr = '""%Owner%"" paketleme ünitesi küme katsayısı 1 ve ölçü birimi ""%UnitOfMeasure%"" olan paketleme ünitesi artık oluşturuldu.?'");
			EndIf;
			
			MessageText = StrReplace(MessageText, "%Owner%", 		   String(Object.Owner));
			MessageText = StrReplace(MessageText, "%UnitOfMeasure%", String(Object.UnitOfMeasure));
			
			Cancel = True;
			
			Buttons = New ValueList();
			Buttons.Add(DialogReturnCode.Yes, NStr("vi = 'Ghi lại';
													|ru = 'Записать';
													|en = 'Save'; fa = 'ذخیره';
													|it = 'Salvare';
													|pl = 'Save';
													|tr = 'Kaydet'")); 
			Buttons.Add(DialogReturnCode.No, NStr("vi = 'Không ghi lại';
													|ru = 'Не записывать';
													|en = 'Discard'; fa = 'Discard';
													|it = 'Non registrare';
													|pl = 'Nie zapisuj';
													|tr = 'Kaydetmemek'"));
			
			ShowQueryBox(
				New CallbackDescription("BeforeWriteCompletion", ThisObject), 
				MessageText, 
				Buttons,
				,
				,
				NStr("vi = 'Sao chép đơn vị tính';
					|ru = 'Дублирование единичной упаковки';
					|en = 'Packaging unit duplicate'; fa = 'Packaging unit duplicate';
					|it = 'Duplicazione di un singolo imballaggio';
					|pl = 'Powielanie pojedynczego opakowania';
					|tr = 'Birim paketleme ünitesinin kopyalanması'"));
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	// StandardSubsystems.Core
	NationalLanguageSupportServer.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Core
	
	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	ObjectAttributesLock.LockAttributes(ThisObject);
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure HeightOnChange(Item)
	RecalculateVolume();
EndProcedure

&AtClient
Procedure DepthOnChange(Item)
	RecalculateVolume();
EndProcedure

&AtClient
Procedure WidthOnChange(Item)
	RecalculateVolume();
EndProcedure

&AtClient
Procedure DimensionlessOnChange(Item)
	CustomizeForm();
EndProcedure

&AtClient
Procedure StandardSizeOnChange(Item)
	StandardSizeOnChangeServer();
EndProcedure

&AtClient
Procedure ZoomRatioOnChange(Item)
	WorkOutLogicOfConnectionDetails();
EndProcedure

&AtClient
Procedure UnitOfMeasureOnChange(Item)
	
	Object.Description = UpdateDescription(Object.PackageType, Object.UnitOfMeasure, Object.Numerator, Object.Denominator, OwnerUnitOfMeasure);
	CustomizeForm();
	
EndProcedure

&AtClient
Procedure PackageTypeWhenChanged(Item)
	If Object.PackageType = PredefinedValue("Enum.TypesOfItemsPackages.Unpacking") Then
		Object.SuppliedInReusablePackage  = False;
		Object.ReusablePackageItems   = Undefined;
		Object.ReusablePackageVariant = Undefined;
		ItemVariantsAreUsed = False;
	EndIf;
	
	WorkOutLogicOfConnectionDetails();
	
EndProcedure

&AtClient
Procedure NumberOfPackagesOnChange(Item)
	
	WorkOutLogicOfConnectionDetails();	
	
EndProcedure

&AtClient
Procedure ParentOnChange(Item)
	WorkOutLogicOfConnectionDetails();	
EndProcedure

&AtClient
Procedure SuppliedInReusablePackageOnChange(Item)
	
	If Not Object.SuppliedInReusablePackage Then
		Object.ReusablePackageItems   = Undefined;
		Object.ReusablePackageVariant = Undefined;
		Object.MinimumNumberOfReusablePackages = 0;
		PackageSelectionOption = 0;
		ItemVariantsAreUsed = False;
	EndIf;
	
	CustomizeForm();
	
EndProcedure

&AtClient
Procedure ReusablePackageItemsOnChange(Item)
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", Object.ReusablePackageVariant);

	StringStructure = New Structure;
	StringStructure.Insert("Products", Object.ReusablePackageItems);
	StringStructure.Insert("Characteristic", Object.ReusablePackageVariant);
	StringStructure.Insert("ItemVariantsAreUsed", ItemVariantsAreUsed);
	
	BatchProcessingOfTablePartClient.ProcessTSString(StringStructure, StructureOfActions, CachedValues);

	Object.ReusablePackageItems = StringStructure.Products;
	Object.ReusablePackageVariant = StringStructure.Characteristic;
	ItemVariantsAreUsed = StringStructure.ItemVariantsAreUsed;

	CustomizeForm();
	
EndProcedure

&AtClient
Procedure WidthUnitOfMeasureClick(Item, StandardProcessing)
	UnitOfMeasurementClick("WidthUnitOfMeasure", StandardProcessing, PredefinedValue("Enum.TypesOfMeasuredValues.Length"));
EndProcedure

&AtClient
Procedure DepthUnitOfMeasureClick(Item, StandardProcessing)
	UnitOfMeasurementClick("DepthUnitOfMeasure", StandardProcessing, PredefinedValue("Enum.TypesOfMeasuredValues.Length"));
EndProcedure

&AtClient
Procedure HeightUnitOfMeasureClick(Item, StandardProcessing)
	UnitOfMeasurementClick("HeightUnitOfMeasure", StandardProcessing, PredefinedValue("Enum.TypesOfMeasuredValues.Length"));
EndProcedure

&AtClient
Procedure VolumeUnitOfMeasureClick(Item, StandardProcessing)
	UnitOfMeasurementClick("VolumeUnitOfMeasure", StandardProcessing, PredefinedValue("Enum.TypesOfMeasuredValues.VolumeM3"));
EndProcedure

&AtClient
Procedure WeightUnitOfMeasureClick(Item, StandardProcessing)
	UnitOfMeasurementClick("WeightUnitOfMeasure", StandardProcessing, PredefinedValue("Enum.TypesOfMeasuredValues.Weight"));
EndProcedure

&AtClient
Procedure TheOptionOfSelectingThePackagingWhenChanging(Item)
	
	OptionForSelectingContainersWhenChangingOnServer();
	
EndProcedure

&AtClient
Procedure TheOptionOfSelectingTheContainerPartiallyOnChange(Item)
	
	OptionForSelectingContainersWhenChangingOnServer();
	
EndProcedure

&AtClient
Procedure Attachable_Opening(Item, StandardProcessing)
	// StandardSubsystems.Core
	NationalLanguageSupportClient.OnOpen(ThisObject, Object, Item, StandardProcessing);
	// End StandardSubsystems.Core
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// Handler for a command created by the mechanism that prohibits editing key details.
//
&AtClient
Procedure Attachable_AllowObjectAttributeEdit(Command)
	
	If Not Object.Ref.IsEmpty() Then
		OpenForm("Catalog.PackagesAndUnitsOfMeasure.Form.UnlockPackageAttributes",,,,,, 
			New CallbackDescription("Attachable_AllowObjectAttributeEditCompletion", ThisObject), 
			FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_AllowObjectAttributeEditCompletion(Result, AdditionalParameters) Export
	
	If TypeOf(Result) = Type("Array")
		And Result.Count() > 0 Then
		
		ObjectAttributesLockClient.SetFormItemEnabled(ThisObject, Result);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure CustomizeForm()
	
	UseReusablePackage         = GetFunctionalOption("UseReusablePackage");
	UseItemVariants = GetFunctionalOption("UseItemVariants");
	UseWarehouseManagementSystem             = GetFunctionalOption("UseWarehouseManagementSystem");
	
	If TypeOf(Object.Owner) = Type("CatalogRef.Products") Then
		Items.Owner.Title = NStr("vi = 'Mặt hàng';
								|ru = 'Номенклатура';
								|en = 'Items'; fa = 'اقلام';
								|it = 'Articolo';
								|pl = 'Items';
								|tr = 'Öğe'");
		Items.WarningDecoration.Visible = False;
	Else
		Items.Owner.Title = NStr("vi = 'Đơn vị đóng gói';
								|ru = 'Набор упаковок';
								|en = 'Packaging group'; fa = 'گروه بسته‌بندی';
								|it = 'Insieme di imballaggi';
								|pl = 'Zestaw opakowań';
								|tr = 'Paketleme grubu'");
		Items.WarningDecoration.Visible = True;
	EndIf;

	If ValueIsFilled(Object.UnitOfMeasure) Then
		UnitOfMeasurePresentation = String(Object.UnitOfMeasure);
	Else
		UnitOfMeasurePresentation =  NStr("vi = '<đvt theo bảng phân loại>';
											|ru = '<ед. изм. по классификатору>';
											|en = '<Unit from classifier>'; fa = '<Unit from classifier>';
											|it = '<un. di mis. per classificatore>';
											|pl = '<j.m. wg klasyfikatora>';
											|tr = '<sınıflandırıcıya göre ölçü birimi>'");
	EndIf;
	
	PresentationText = NStr("vi = '1 %UnitByClassifier% tạo từ';
							|ru = '1 %UnitByClassifier% состоит из';
							|en = 'Single %UnitByClassifier% contains'; fa = 'Single %UnitByClassifier% contains';
							|it = '1 %UnitByClassifier%  consta di';
							|pl = '1 %UnitByClassifier% składa się z';
							|tr = '1 %UnitByClassifier% oluşur'");
	PresentationText = StrReplace(PresentationText, "%UnitByClassifier%", UnitOfMeasurePresentation);
	SelectionPoint = Items.PackageType1.ChoiceList.FindByValue(Enums.TypesOfItemsPackages.Final);
	SelectionPoint.Presentation = PresentationText;
	
	PresentationText = NStr("vi = '1 %UnitByClassifier% tạo từ';
							|ru = '1 %UnitByClassifier% состоит из';
							|en = 'Single %UnitByClassifier% contains'; fa = 'Single %UnitByClassifier% contains';
							|it = '1 %UnitByClassifier%  consta di';
							|pl = '1 %UnitByClassifier% składa się z';
							|tr = '1 %UnitByClassifier% oluşur'");
	PresentationText = StrReplace(PresentationText, "%UnitByClassifier%", UnitOfMeasurePresentation);
	SelectionPoint = Items.PackageType2.ChoiceList.FindByValue(Enums.TypesOfItemsPackages.Complex);
	SelectionPoint.Presentation = PresentationText;
	
	PresentationText = NStr("vi = '1 %OwnerUnitOfMeasure% tạo từ';
							|ru = '1 %OwnerUnitOfMeasure% состоит из';
							|en = 'Single %OwnerUnitOfMeasure% contains'; fa = 'Single %OwnerUnitOfMeasure% contains';
							|it = '1 %OwnerUnitOfMeasure% consta di';
							|pl = '1 %OwnerUnitOfMeasure% składa się z';
							|tr = '1 %OwnerUnitOfMeasure% oluşur'");
	PresentationText = StrReplace(PresentationText, "%OwnerUnitOfMeasure%", OwnerUnitOfMeasure);
	SelectionPoint = Items.PackageType3.ChoiceList.FindByValue(Enums.TypesOfItemsPackages.Unpacking);
	SelectionPoint.Presentation = PresentationText;
	
	If UseWarehouseManagementSystem Then
		PresentationText = NStr("vi = 'Có trong %OwnerUnitOfMeasure% với số lượng';
								|ru = 'Входит в состав %OwnerUnitOfMeasure% в количестве';
								|en = 'Part of %OwnerUnitOfMeasure% contains'; fa = 'Part of %OwnerUnitOfMeasure% contains';
								|it = 'Incluso in %OwnerUnitOfMeasure% in numero';
								|pl = 'Wchodzi w skład %OwnerUnitOfMeasure% w ilości';
								|tr = 'Miktarda %OwnerUnitOfMeasure% içeriğine dahildir'");
		PresentationText = StrReplace(PresentationText, "%OwnerUnitOfMeasure%", OwnerUnitOfMeasure);
		
		SelectionPoint = Items.PackageType4.ChoiceList.FindByValue(Enums.TypesOfItemsPackages.CargoItem);
		SelectionPoint.Presentation = PresentationText;
	EndIf;
	
	Items.DecorationNumeratorUnit.Title = ?(ValueIsFilled(OwnerUnitOfMeasure),
																String(OwnerUnitOfMeasure),
																NStr("vi = 'Hiển thị phần tử số của đơn vị tính';
																	|ru = 'Декорация числитель единица измерения';
																	|en = 'Decoration Numerator unit of measure'; fa = 'تزئین واحد اندازه‌گیری صورت';
																	|it = 'Decoration Numerator unit of measure';
																	|pl = 'Decoration Numerator unit of measure';
																	|tr = 'Dekorasyon payda ölçü birimi'"));
	
	DenominatorRepresentations = New Array;
	If ValueIsFilled(Object.UnitOfMeasure) Then
		DenominatorRepresentations.Add(UnitOfMeasurePresentation);
	EndIf;
	DenominatorRepresentations.Add(NStr("vi = '(tách bộ)';
										|ru = '(разупаковка)';
										|en = '(disassembly)'; fa = '(disassembly)';
										|it = '(disassembly)';
										|pl = '(disassembly)';
										|tr = '(paketleme ünitesinden çıkarma)'"));
	
	Items.DecorationUnpacking.Title = StrConcat(DenominatorRepresentations, " ");
	
	Items.DecorationUnit.Title = ?(ValueIsFilled(Object.UnitOfMeasure),
													UnitOfMeasurePresentation,
													NStr("vi = 'Trang trí đơn vị tính';
														|ru = 'Декорация единица измерения';
														|en = 'Decoration Unit of measure'; fa = 'تزئین واحد اندازه‌گیری';
														|it = 'Decoration Unit of measure';
														|pl = 'Decoration Unit of measure';
														|tr = 'Dekorasyon ölçü birimi'"));
	
	Items.DecorationNumeratorUnit.Visible = ValueIsFilled(OwnerUnitOfMeasure);
	
	Items.PackageType4.Visible					= UseWarehouseManagementSystem;
	Items.NumberOfPackages1.Visible			= UseWarehouseManagementSystem;
	Items.DecorationUnit.Visible	= UseWarehouseManagementSystem
														And ValueIsFilled(Object.UnitOfMeasure);
	
	Items.PackageType3.Visible         = Not Catalogs.PackagesAndUnitsOfMeasure.ThisIsADimensionalUnit(OwnerUnitOfMeasure);
	Items.Denominator.Visible          = Items.PackageType3.Visible;
	Items.DecorationUnpacking.Visible = Items.PackageType3.Visible;
	
	Items.Numerator.Enabled = Object.PackageType = Enums.TypesOfItemsPackages.Final;
	Items.Numerator.Parent.Enabled = Object.PackageType = Enums.TypesOfItemsPackages.Final;
	
	Items.NumberOfPackages.Enabled          = Object.PackageType = Enums.TypesOfItemsPackages.Complex;
	Items.NumberOfPackages.Parent.Enabled = Object.PackageType = Enums.TypesOfItemsPackages.Complex;
	
	Items.Denominator.Enabled = Object.PackageType = Enums.TypesOfItemsPackages.Unpacking;
	Items.Denominator.Parent.Enabled = Object.PackageType = Enums.TypesOfItemsPackages.Unpacking;
	
	Items.NumberOfPackages1.Enabled		= (Object.PackageType = Enums.TypesOfItemsPackages.CargoItem);
	Items.DecorationUnit.Enabled	= (Object.PackageType = Enums.TypesOfItemsPackages.CargoItem);
	
	Items.SuppliedInReusablePackage.Visible   = UseReusablePackage;
	Items.SuppliedInReusablePackage.Enabled = Object.PackageType <> Enums.TypesOfItemsPackages.Unpacking;
	
	Items.ReusablePackageItems.Visible   = Object.SuppliedInReusablePackage;
	Items.ReusablePackageVariant.Visible = Object.SuppliedInReusablePackage
															And UseItemVariants;
	Items.ReusablePackageVariant.Enabled = ItemVariantsAreUsed;
	Items.MinimumNumberOfReusablePackages.Visible = Object.SuppliedInReusablePackage;
	Items.PackagingSelectionOptions.Visible = Object.SuppliedInReusablePackage And UseReusablePackage;
		
	Items.Height.Enabled  = Not Object.Dimensionless;
	Items.Depth.Enabled = Not Object.Dimensionless;
	Items.Width.Enabled  = Not Object.Dimensionless;
	Items.VolumeM3.Enabled   = Not Object.Dimensionless;
	
	Items.MinimumNumberOfReusablePackages.MaxValue = ?(Object.PackageType = Enums.TypesOfItemsPackages.Complex,
																						Object.NumberOfPackages-1,
																						Object.Numerator);
	
	Items.FullContainerSelectionOption.ChoiceList[0].Presentation = FormStringOfContainerSelectionOptions(0);
	Items.TheOptionOfSelectingTheContainerPartially.ChoiceList[0].Presentation = FormStringOfContainerSelectionOptions(1);
	
	If Object.MinimumNumberOfReusablePackages > 0 Then
		PackageSelectionOption = 1;
		Items.MinimumNumberOfReusablePackages.Enabled = True;
	Else
		PackageSelectionOption = 0;
		Items.MinimumNumberOfReusablePackages.Enabled = False;
	EndIf;
	
	If OwnerSUnitOfMeasurementType = Enums.TypesOfMeasuredValues.NumberOfPieces Then
		Items.Numerator.MinValue = 1;
	Else
		Items.Numerator.MinValue = 0.001;
	EndIf;
	
	Items.WeightUnitOfMeasure.Enabled = AccessRight("Edit", Metadata.Catalogs.PackagesAndUnitsOfMeasure);
	Items.VolumeUnitOfMeasure.Enabled = AccessRight("Edit", Metadata.Catalogs.PackagesAndUnitsOfMeasure);
	Items.DepthUnitOfMeasure.Enabled = AccessRight("Edit", Metadata.Catalogs.PackagesAndUnitsOfMeasure);
	Items.WidthUnitOfMeasure.Enabled = AccessRight("Edit", Metadata.Catalogs.PackagesAndUnitsOfMeasure);
	Items.HeightUnitOfMeasure.Enabled = AccessRight("Edit", Metadata.Catalogs.PackagesAndUnitsOfMeasure);
	
EndProcedure

#Region OnChangeAttributes

&AtServer
Procedure WorkOutLogicOfConnectionDetails()
	
	Catalogs.PackagesAndUnitsOfMeasure.WorkOutLogicOfConnectionDetails(Object);
	Object.Description = UpdateDescription(Object.PackageType, Object.UnitOfMeasure, Object.Numerator, Object.Denominator, OwnerUnitOfMeasure );
	If Object.PackageType = Enums.TypesOfItemsPackages.Complex Then
		If Object.NumberOfPackages < Object.MinimumNumberOfReusablePackages Then
			Object.MinimumNumberOfReusablePackages = Object.NumberOfPackages;
		EndIf;
	Else
		If Object.Numerator < Object.MinimumNumberOfReusablePackages Then
			Object.MinimumNumberOfReusablePackages = Object.Numerator;
		EndIf;
	EndIf;
	
	CustomizeForm();
	
EndProcedure

#EndRegion

#Region Other

&AtClient
Procedure BeforeWriteCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.No Then
		Return;
	EndIf;
	
	RecordingIsInProgress = True;
	Write();
	RecordingIsInProgress = False;
	
EndProcedure

&AtClient
Procedure UnitOfMeasurementClick(FieldName, StandardProcessing, MeasuredValueType)
	
	StandardProcessing = False;
	CallbackDescription = New CallbackDescription("UnitOfMeasurementClickCompletion", ThisObject, New Structure("FieldName", FieldName));
	
	Filter = New Structure;
	Filter.Insert("MeasuredValueType", MeasuredValueType);
	
	OpenForm("Catalog.PackagesAndUnitsOfMeasure.ChoiceForm",
				New Structure("Filter,CurrentRow", Filter, Object[FieldName]),
				ThisObject,
				,
				,
				,
				CallbackDescription,
				FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure UnitOfMeasurementClickCompletion(Result, AdditionalParameters) Export

	If Result <> Undefined Then
		Modified = True;

		If AdditionalParameters.FieldName = "VolumeUnitOfMeasure"
			Or AdditionalParameters.FieldName = "DepthUnitOfMeasure"
			Or AdditionalParameters.FieldName = "WidthUnitOfMeasure"
			Or AdditionalParameters.FieldName = "HeightUnitOfMeasure" Then
			SetUnitOfDimension(AdditionalParameters.FieldName, Result);
		ElsIf AdditionalParameters.FieldName = "WeightUnitOfMeasure" Then
			SetUnit(AdditionalParameters.FieldName, Result);
		Else
			Object[AdditionalParameters.FieldName] = Result;
		EndIf;

	EndIf;

EndProcedure

&AtServer
Procedure SetUnit(Attribute, Value)

	Object[Attribute] = Value;

EndProcedure

&AtServer
Procedure SetUnitOfDimension(Attribute, Value)

	SetUnit(Attribute, Value);
	RecalculateVolume();

EndProcedure

&AtServer
Procedure RecalculateVolume()
	
	If Object.WidthUnitOfMeasure = Catalogs.PackagesAndUnitsOfMeasure.EmptyRef()
		Or Object.DepthUnitOfMeasure = Catalogs.PackagesAndUnitsOfMeasure.EmptyRef()
		Or Object.HeightUnitOfMeasure = Catalogs.PackagesAndUnitsOfMeasure.EmptyRef()
		Or Object.VolumeUnitOfMeasure = Catalogs.PackagesAndUnitsOfMeasure.EmptyRef() Then
		
		Object.VolumeM3 = 0;
		
	Else
		
		Query = New Query;
		Query.Text = 
		"SELECT
		|	CAST(&WidthUnitOfMeasure AS Catalog.PackagesAndUnitsOfMeasure).Numerator / CAST(&WidthUnitOfMeasure AS Catalog.PackagesAndUnitsOfMeasure).Denominator AS CoefficientWidth,
		|	CAST(&HeightUnitOfMeasure AS Catalog.PackagesAndUnitsOfMeasure).Numerator / CAST(&HeightUnitOfMeasure AS Catalog.PackagesAndUnitsOfMeasure).Denominator AS CoefficientHeight,
		|	CAST(&DepthUnitOfMeasure AS Catalog.PackagesAndUnitsOfMeasure).Numerator / CAST(&DepthUnitOfMeasure AS Catalog.PackagesAndUnitsOfMeasure).Denominator AS CoefficientDepth,
		|	CAST(&VolumeUnitOfMeasure AS Catalog.PackagesAndUnitsOfMeasure).Numerator / CAST(&VolumeUnitOfMeasure AS Catalog.PackagesAndUnitsOfMeasure).Denominator AS FactorVolume";
		
		Query.SetParameter("WidthUnitOfMeasure", 	Object.WidthUnitOfMeasure);
		Query.SetParameter("HeightUnitOfMeasure", 	Object.HeightUnitOfMeasure);
		Query.SetParameter("DepthUnitOfMeasure", 	Object.DepthUnitOfMeasure);
		Query.SetParameter("VolumeUnitOfMeasure", 		Object.VolumeUnitOfMeasure);		
		
		Selection = Query.Execute().Select();
		
		While Selection.Next() Do 
			Object.VolumeM3 = Object.Height * Selection.CoefficientHeight * Object.Depth * Selection.CoefficientDepth * Object.Width * Selection.CoefficientWidth / Selection.FactorVolume;	
		EndDo;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure StandardSizeOnChangeServer()
	Result = Common.ObjectAttributesValues(Object.StandardSize, "Depth, DepthUnitOfMeasure, Width, WidthUnitOfMeasure, Height, HeightUnitOfMeasure, VolumeM3, VolumeUnitOfMeasure, Dimensionless");
	FillPropertyValues(Object, Result);
	CustomizeForm();
EndProcedure

&AtServerNoContext
Function UpdateDescription(PackageType, UnitOfMeasure, Numerator, Denominator, OwnerUnitOfMeasure)
	Return Catalogs.PackagesAndUnitsOfMeasure.GenerateName(PackageType, UnitOfMeasure, Numerator, Denominator, OwnerUnitOfMeasure);	
EndFunction

&AtServer
Procedure OnReadCreateAtServer()
	
	UpdateParentSCoefficient();
	ResultingStructure = Common.ObjectAttributesValues(Object.Owner,
		New Structure("UnitOfMeasure, MeasuredValueType", "UnitOfMeasure", "UnitOfMeasure.MeasuredValueType"));
	OwnerUnitOfMeasure = ResultingStructure.UnitOfMeasure;
	OwnerSUnitOfMeasurementType = ResultingStructure.MeasuredValueType;
	ItemVariantsAreUsed = Catalogs.Products.ItemVariantsAreUsed(Object.ReusablePackageItems);
	CustomizeForm();
	
EndProcedure

&AtServer
Procedure UpdateParentSCoefficient()
	
	If Object.PackageType = Enums.TypesOfItemsPackages.Complex Then
		Result = Catalogs.PackagesAndUnitsOfMeasure.CoefficientWeightVolumeOtherPackingDetails(Object.Parent,
			Undefined,
			"Numerator, Denominator");
		ParentNumerator = Result.Numerator;
		ParentDenominator = Result.Denominator;
	Else
		ParentNumerator = 1;
		ParentDenominator = 1;
	EndIf;
	
EndProcedure

&AtServerNoContext
Function ThereIsUnitPackageWithUnitOfMeasurement(Ref, Owner, UnitOfMeasure)
	
	Query = New Query;
	QueryText = 
	"SELECT TOP 1
	|	&QueryTextPackagingFactor AS NumberOfSinglePackages,
	|	ProductPackages.Owner,
	|	ProductPackages.Ref
	|FROM
	|	Catalog.PackagesAndUnitsOfMeasure AS ProductPackages
	|WHERE
	|	&QueryTextPackagingFactor = 1
	|	AND ProductPackages.DeletionMark = FALSE
	|	AND ProductPackages.Owner = &Owner
	|	AND ProductPackages.UnitOfMeasure = &UnitOfMeasure";
	
	QueryText = StrReplace(QueryText, "&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient("ProductPackages", Undefined));
	
	Query.Text = QueryText;
	
	Query.SetParameter("Owner", Owner);
	Query.SetParameter("UnitOfMeasure", UnitOfMeasure);
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		Return True;
	Else
		
		If Not ValueIsFilled(Ref) Then
			Return	False;
		Else
			Selection = QueryResult.Select();
			Selection.Next();
			Return Selection.Ref = Ref;
		EndIf;
		
	EndIf;
	
EndFunction

&AtServer
Procedure OptionForSelectingContainersWhenChangingOnServer()
	
	If PackageSelectionOption =0 Then
		Object.MinimumNumberOfReusablePackages = 0;
		Items.MinimumNumberOfReusablePackages.Enabled = False;
	Else 
		Object.MinimumNumberOfReusablePackages = ?(Object.MinimumNumberOfReusablePackages = 0,1,Object.MinimumNumberOfReusablePackages);
		Items.MinimumNumberOfReusablePackages.Enabled = True;
	EndIf;
	
EndProcedure

&AtServer
Function FormStringOfContainerSelectionOptions(OptionNumber)
	
	OptionRow = "";
	NumberOfUnitsPerPack = 0;
	If Object.PackageType = Enums.TypesOfItemsPackages.Complex Then
		NumberOfUnitsPerPack  = Object.NumberOfPackages;	
		UnitOfMeasure = Common.ObjectAttributeValue(Object.Parent, "UnitOfMeasure");
	Else
		NumberOfUnitsPerPack  = Object.Numerator;	
		UnitOfMeasure = OwnerUnitOfMeasure;
	EndIf;
	If OptionNumber = 0 Then
		If ValueIsFilled(OwnerUnitOfMeasure) Then
			OptionRow = StrTemplate(NStr("vi = ' đầy đủ (%1 %2)';
										|ru = ' полностью (%1 %2)';
										|en = ' in full (%1 %2)'; fa = ' in full (%1 %2)';
										|it = ' interamente (%1 %2)';
										|pl = ' w całości (%1 %2)';
										|tr = ' tamamen (%1 %2)'"),NumberOfUnitsPerPack,UnitOfMeasure);	
		Else
			OptionRow = StrTemplate(NStr("vi = ' đầy đủ (%1)';
										|ru = ' полностью (%1)';
										|en = ' in full (%1)'; fa = ' in full (%1)';
										|it = ' interamente (%1)';
										|pl = ' w całości (%1)';
										|tr = ' tamamen (%1)'"),NumberOfUnitsPerPack);
		EndIf;
	ElsIf OptionNumber = 1 Then
		OptionRow = NStr("vi = ' bắt đầu từ';
						|ru = ' начиная с';
						|en = ' starting with'; fa = ' starting with';
						|it = ' a decorrere da';
						|pl = ' zaczynając od';
						|tr = ' başlayarak'");		
	EndIf;
	Items.UnitOfMeasureLabel.Title = StrTemplate(NStr("vi = '%1';
														|ru = '%1';
														|en = '%1'; fa = '%1';
														|it = '%1';
														|pl = '%1';
														|tr = '%1'"),UnitOfMeasure);

	Return OptionRow;
	
EndFunction

#EndRegion

#EndRegion

#Region Initialize

RecordingIsInProgress = False;

#EndRegion
