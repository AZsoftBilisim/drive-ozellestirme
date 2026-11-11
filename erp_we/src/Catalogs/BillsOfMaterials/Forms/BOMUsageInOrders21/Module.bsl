
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	SubsystemSettingsProduction = ProductionServer.SubsystemSettingsProduction();
	If Not SubsystemSettingsProduction.ProductionIsUsed Then 
		Raise NStr("vi = 'Để mở biểu mẫu, cần bật sử dụng phân hệ quản lý sản xuất.';
					|ru = 'Для открытия формы необходимо включить подсистему управления производством.';
					|en = 'Enable production management subsystem to open the form.'; fa = 'Enable production management subsystem to open the form.';
					|it = 'Per aprire il form, è necessario abilitare il sottosistema di gestione della produzione.';
					|pl = 'Aby otworzyć formularz, należy włączyć podsystem zarządzania produkcją.';
					|tr = 'Formun açılması için üretim yönetimi alt sistemini etkinleştirmeniz gerekmektedir.'");
	EndIf;
	FillPropertyValues(ThisForm, SubsystemSettingsProduction);
	
	Items.OrderListScheduleState.Visible = True;
	
	BillOfMaterials = Parameters.BillOfMaterials;
	
	FillInServiceDetails();
	
	FillInListOfOrders();

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	CustomizeFormElements();
	
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	If StrFind("Write_ProductionOrder, Write_ProductionStages, Write_ProductionSchedule", EventName) > 0
		And Source <> "UsageOfBOMInOrders" Then
		FillInListOfOrders();
	EndIf; 
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	If ChoiceSource.FormName = "Catalog.BillsOfMaterials.Form.ChoiceFormByItems" Then
		ReplaceBORCompletion(ValueSelected);
	EndIf; 
	Return; // empty handler
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersOrderList

&AtClient
Procedure OrderListSelection(Item, RowSelected, Field, StandardProcessing)
	StandardProcessing = False;
	
	CurrentData = Items.OrderList.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	
	Return; // empty handler
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ReplaceSpecificationCommand(Command)
	
	SelectedLinesForWhichProductionIsNotStarted = False;
	ExcludeSpecificationFromSelection = Undefined;
	
	DataOfSelectedRows = New Array;
	For Each RowData In OrderList Do
		RowID = RowData.GetID();
		If Items.OrderList.SelectedRows.Find(RowID) = Undefined Then
			RowData.Replace = False;
			Continue;
		EndIf;
		RowData.Replace = True;
		
		StructureOfData = ProductDataManagementClientServer.ProductDataStructureForSpecificationSelection();
		StructureOfData.Products            = RowData.Products;
		StructureOfData.Characteristic          = RowData.Characteristic;
		StructureOfData.ProductionStart      = RowData.ProductionStart;
		StructureOfData.ProductionDispatcherBusinessUnit  = RowData.Department;
		StructureOfData.LineOfBusiness = RowData.LineOfBusiness;
		DataOfSelectedRows.Add(StructureOfData);
		
		If Not RowData.ProductionStarted Then
			SelectedLinesForWhichProductionIsNotStarted = True;
		EndIf;
		
		If Not RowData.CurrentBillOfMaterialsIsNoLongerUsed Then
			// the line for which the current specification
			// is used is selected, so we forbid the selection of the current specification for replacement
			ExcludeSpecificationFromSelection = BillOfMaterials;
		EndIf;
	EndDo;
	
	If DataOfSelectedRows.Count() = 0 Then
		ShowMessageBox(, NStr("vi = 'Cần chọn các dòng cần thay thế.';
								|ru = 'Необходимо выбрать строки, в которых требуется выполнить замену.';
								|en = 'Select lines in which replacement should be made.'; fa = 'Select lines in which replacement should be made.';
								|it = 'È necessario selezionare le righe in cui si desidera eseguire la sostituzione.';
								|pl = 'Należy wybrać wiersze, w których trzeba dokonać zamiany.';
								|tr = 'Değişiklik yapacağınız satırları seçmeniz gerekmektedir.'"));
		Return;
		
	ElsIf Not SelectedLinesForWhichProductionIsNotStarted Then
		ShowMessageBox(, NStr("vi = 'Chỉ cho phép thay thế bảng kê chi tiết đối với thành phẩm và bán sản phẩm,
											|mà đã khởi động quá trình sản xuất (dự tính).';
											|ru = 'Замена спецификации допускается только для продукции и полуфабрикатов,
											|производство которых не запущено (запланировано).';
											|en = 'BOM replacement is allowed only for products and semi-finished products 
											|whose manufacturing is not started (planned).'; fa = 'BOM replacement is allowed only for products and semi-finished products 
											|whose manufacturing is not started (planned).';
											|it = 'La sostituzione della specifica è consentita solo per prodotti e semilavorati,
											|la cui produzione non è iniziata (pianificata).';
											|pl = 'Zamiana specyfikacji jest możliwa tylko dla produkcji i półproduktów,
											|których produkcja nie jest uruchomiona (zaplanowana).';
											|tr = 'Ürün reçetesi değişikliğine sadece üretimine başlanmamış,
											|(planlanmamış) imal edilecek ürünler ve yarı mamul ürünler için izin verilmektedir.'"));
		Return;
	EndIf;
	
	BOMSelectionParameters = ProductDataManagementClientServer.BOMSelectionParameters();
	
	AvailableTypes = BOMSelectionParameters.AvailableTypes; // Array
	AvailableTypes.Add(ProductionProcessType);
	
	AvailableStatuses = BOMSelectionParameters.AvailableStatuses; // Array
	AvailableStatuses.Add(PredefinedValue("Enum.BOMStatuses.Valid"));
	
	BOMSelectionParameters.Insert("ExcludeSpecification", ExcludeSpecificationFromSelection);
	
	ProductDataManagementClient.OpenFormForSelectingSpecificationsFromListOfProducts(DataOfSelectedRows, BOMSelectionParameters, ThisForm);
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure Refresh(Command)
	FillInListOfOrders();
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure CustomizeFormElements()
	
	LegendLines = New Array;
	LegendLines.Add(NStr("vi = 'Thành phẩm hoặc bán thành phẩm đã khởi động quá trình sản xuất được đánh dấu màu nâu.';
						|ru = 'Коричневым выделена продукция или полуфабрикаты, производство которых уже запущено.';
						|en = 'Products or semi-finished products whose manufacturing has started are highlighted in brown.'; fa = 'Products or semi-finished products whose manufacturing has started are highlighted in brown.';
						|it = 'La produzione o semilavorati sono evidenziati di marrone, se la loro produzione è già avviata.';
						|pl = 'Brązowym kolorem jest wyróżniona produkcja lub półprodukty, których produkcja jest już uruchomiona.';
						|tr = 'Kahverengi ile üretimi halihazırda başlatılmış imal edilen ürünler veya yarı mamul ürünler vurgulanmıştır.'"));
	If ThisIsTechnologicalSet Then
		Items.OrderListReplaceBOR.Visible = False;
	Else
		LegendLines.Add(NStr("vi = 'Thành phẩm hoặc bán thành phẩm đã thực hiện thay thế bảng kê chi tiết và bảng kê chi tiết hiện tại không còn sử dụng được đánh dấu màu xám.';
							|ru = 'Серым выделена продукция или полуфабрикаты, для которых выполнена замена спецификации и текущая спецификация больше не используется.';
							|en = 'Products or semi-finished products for which the BOM is replaced, and the current BOM is no longer used, are highlighted in gray.'; fa = 'Products or semi-finished products for which the BOM is replaced, and the current BOM is no longer used, are highlighted in gray.';
							|it = 'La produzione e semilavorati sono evidenziati di grigio, se per loro è stata eseguita la sostituzione delle specifiche e della configurazione corrente non è più utilizzata.';
							|pl = 'Szarym kolorem jest wyróżniona produkcja lub półprodukty, dla których jest wykonane zastąpienie specyfikacji i bieżąca specyfikacja więcej nie jest używana.';
							|tr = 'Ürün reçetesinin değiştirildiği ve mevcut ürün reçetesinin artık kullanılmadığı imal edilen ürünler veya yarı mamul ürünler gri renkte vurgulanmıştır.'"));
	EndIf;
	Items.Legend.Title = StrConcat(LegendLines, Chars.LF);
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();
		
EndProcedure

&AtServer
Procedure FillInServiceDetails()
	
	QueryText = "
	|SELECT
	|	T.ProductionProcessType                                                                   AS ProductionProcessType,
	|	T.MainProductProductKind.ItemsType = VALUE(Enum.ItemsTypes.Set) AS ThisIsTechnologicalSet
	|FROM
	|	Catalog.BillsOfMaterials AS T
	|
	|WHERE
	|	T.Ref = &BillOfMaterials
	|";
	
	Query = New Query(QueryText);
	Query.SetParameter("BillOfMaterials", BillOfMaterials);
	
	Selection = Query.Execute().Select();
	Selection.Next();
	
	FillPropertyValues(ThisObject, Selection);
	
EndProcedure

&AtServer
Procedure FillInListOfOrders()

	
	DetermineProductionStarted();
	
EndProcedure

&AtServer
Procedure DetermineProductionStarted()

	
EndProcedure

&AtClient
Procedure ReplaceBORCompletion(NewSpecification)

	PerformReplacementsInOrdersOnServer(NewSpecification);
	
	NotifyAboutChanges_ = False;
	
	If TotalReplacements = 0 Then
		
		ShowMessageBox(, NStr("vi = 'Cần chọn các dòng cần thay thế.';
								|ru = 'Необходимо выбрать строки, в которых требуется выполнить замену.';
								|en = 'Select lines in which replacement should be made.'; fa = 'Select lines in which replacement should be made.';
								|it = 'È necessario selezionare le righe in cui si desidera eseguire la sostituzione.';
								|pl = 'Należy wybrać wiersze, w których trzeba dokonać zamiany.';
								|tr = 'Değişiklik yapacağınız satırları seçmeniz gerekmektedir.'"));
		Return;
		
	ElsIf ReplacementsPerformed = TotalReplacements Then
		
		// Successfully replaced in all orders
		TextOfCompletedOperation = NStr("vi = 'Thay thế trong tất cả các dòng đã chọn';
										|ru = 'Выполнена замена во всех выбранных строках';
										|en = 'Replacement is made in all selected lines'; fa = 'Replacement is made in all selected lines';
										|it = 'Sostituito in tutte le righe selezionate';
										|pl = 'Wykonano zamianę we wszystkich wybranych wierszach';
										|tr = 'Seçili tüm satırlarda değişiklik yapıldı'");
		TextExplainingCompletedOperation = StringFunctionsClientServer.SubstituteParametersToString(
														NStr("vi = 'Số lượng dòng đơn hàng đã thay đổi: %1 trong số %2';
															|ru = 'Изменено строк заказов: %1 из %2';
															|en = 'Order lines changed: %1 out of %2'; fa = 'Order lines changed: %1 out of %2';
															|it = 'Righe degli ordini modificate: %1 di %2';
															|pl = 'Zmienione wiersze zamówień: %1 z %2';
															|tr = 'Değiştirilen sipariş satırları: %2 üzerinden %1'"),
														Format(ReplacementsPerformed, "NG=0"),
														Format(TotalReplacements, "NG=0"));
														
		ShowUserNotification(TextOfCompletedOperation,, TextExplainingCompletedOperation);
		
		NotifyAboutChanges_ = True;
		
	ElsIf ReplacementsPerformed = 0 Then
		
		// Couldn't replace in any order
		ShowMessageBox(,NStr("vi = 'Không thể thay thế.';
							|ru = 'Не удалось выполнить замену.';
							|en = 'Cannot replace.'; fa = 'Cannot replace.';
							|it = 'Non è stato possibile effettuare la sostituzione.';
							|pl = 'Zamiana nie powiodła się.';
							|tr = 'Değişiklik yapılamadı.'"));
		Return;
		
	Else
		
		// In some orders could not be replaced
		TextOfCompletedOperation = NStr("vi = 'Không thay thế trong tất cả các dòng đã chọn';
										|ru = 'Замена выполнена не во всех выбранных строках';
										|en = 'Replacement is made not in all selected lines'; fa = 'Replacement is made not in all selected lines';
										|it = 'La sostituzione è stata completata, ma non in tutte le righe selezionate';
										|pl = 'Zamiana została wykonana nie we wszystkich wybranych wierszach';
										|tr = 'Değişiklik, seçili tüm satırlarda yapılmadı'");
		TextExplainingCompletedOperation = StringFunctionsClientServer.SubstituteParametersToString(
														NStr("vi = 'Số lượng dòng đơn hàng đã thay đổi: %1 trong số %2';
															|ru = 'Изменено строк заказов: %1 из %2';
															|en = 'Order lines changed: %1 out of %2'; fa = 'Order lines changed: %1 out of %2';
															|it = 'Righe degli ordini modificate: %1 di %2';
															|pl = 'Zmienione wiersze zamówień: %1 z %2';
															|tr = 'Değiştirilen sipariş satırları: %2 üzerinden %1'"),
														Format(ReplacementsPerformed, "NG=0"),
														Format(TotalReplacements, "NG=0"));
														
		ShowUserNotification(TextOfCompletedOperation,, TextExplainingCompletedOperation);
		
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
										NStr("vi = 'Không thay thế trong tất cả các dòng đơn hàng (trong %1 trong số %2).';
											|ru = 'Замена выполнена не во всех строках заказов (в %1 из %2).';
											|en = 'Replacement is not made in all order lines (in %1 out of %2).'; fa = 'Replacement is not made in all order lines (in %1 out of %2).';
											|it = 'La sostituzione è stata completata, ma non in tutte le righe selezionate (in %1 su %2).';
											|pl = 'Zamiana została wykonana nie we wszystkich wybranych wierszach (w %1 z %2).';
											|tr = 'Değişiklik, seçili tüm satırlarda yapılmadı (%2 üzerinden %1 içinde).'"), 
										Format(ReplacementsPerformed, "NG=0"), 
										Format(TotalReplacements, "NG=0"));
										
		ShowMessageBox(, MessageText);
		
		NotifyAboutChanges_ = True;
		
	EndIf; 
	
	
EndProcedure

&AtServer
Procedure PerformReplacementsInOrdersOnServer(Val NewSpecification)

	
EndProcedure

#EndRegion
