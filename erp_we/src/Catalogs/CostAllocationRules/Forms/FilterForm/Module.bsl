
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	If Parameters.Property("ArrayOfActivities") Then
		LinesOfBusinessList.LoadValues(Parameters.ArrayOfActivities);
		Items.Pages.CurrentPage = Items.LinesOfBusinessPage;
		Title = NStr("vi = 'Danh sách lĩnh vực hoạt động';
					|ru = 'Список направлений деятельности';
					|en = 'Lines of business'; fa = 'خطوط کسب‌وکار';
					|it = 'Elenco dei settori di attività';
					|pl = 'Lista kierunków działalności';
					|tr = 'İş kolları listesi'");
	ElsIf Parameters.Property("ArrayOfMaterials") Then
		MaterialList.LoadValues(Parameters.ArrayOfMaterials);
		Items.Pages.CurrentPage = Items.PageMaterials;
		Title = NStr("vi = 'Danh sách vật liệu';
					|ru = 'Список материалов';
					|en = 'Materials'; fa = 'مواد';
					|it = 'Elenco dei materiali';
					|pl = 'Lista materiałów';
					|tr = 'Malzemeler listesi'");
	ElsIf Parameters.Property("ArrayOfTypesOfWork") Then
		ActivityKindList.LoadValues(Parameters.ArrayOfTypesOfWork);
		Items.Pages.CurrentPage = Items.PageActivityKinds;
		Title = NStr("vi = 'Danh sách các loại công việc của nhân viên';
					|ru = 'Список видов работ сотрудников';
					|en = 'Employee activity kinds'; fa = 'انواع فعالیت کارکنان';
					|it = 'Elenco dei tipi dei lavori dei dipendenti';
					|pl = 'Lista rodzajów prac pracowników';
					|tr = 'Çalışanların iş türlerinin listesi'");
	ElsIf Parameters.Property("ArrayOfDivisions") Then
		DepartmentList.LoadValues(Parameters.ArrayOfDivisions);
		Items.Pages.CurrentPage = Items.DepartmentsPage;
		Title = NStr("vi = 'Danh sách bộ phận';
					|ru = 'Список подразделений';
					|en = 'Business units'; fa = 'واحدهای تجاری';
					|it = 'Elenco dei reparti';
					|pl = 'Lista działów';
					|tr = 'Departmanlar listesi'");
	ElsIf Parameters.Property("ArrayOfProducts_1") Then
		ProductList_.LoadValues(Parameters.ArrayOfProducts_1);
		Items.Pages.CurrentPage = Items.ProductsPage;
		Title = NStr("vi = 'Danh sách sản phẩm';
					|ru = 'Список продукции';
					|en = 'Products'; fa = 'کالاها';
					|it = 'Elenco prodotti';
					|pl = 'Lista produkcji';
					|tr = 'İmal edilen ürünler listesi'");		
	ElsIf Parameters.Property("ArrayOfProductGroups") Then
		ListOfProductGroups.LoadValues(Parameters.ArrayOfProductGroups);
		Items.Pages.CurrentPage = Items.PageProductGroups;
		Title = NStr("vi = 'Danh sách nhóm (dạng) sản phẩm';
					|ru = 'Список групп (видов) продукции';
					|en = 'Manufactured product groups (kinds)'; fa = 'Manufactured product groups (kinds)';
					|it = 'Elenco dei gruppi (tipi) della produzione';
					|pl = 'Lista grup (rodzajów) produkcji';
					|tr = 'İmal edilen ürün grupları (türleri) listesi'");
	Else
		Items.Pages.Visible = False;
	EndIf;
	Items.ListOfProductGroupsValue.ChoiceFoldersAndItems = FoldersAndItems.Items;
	Items.ProductListValue.ChoiceFoldersAndItems = FoldersAndItems.Items;
	Items.ListOfMaterialsValue.ChoiceFoldersAndItems = FoldersAndItems.FoldersAndItems;
	
	ArrayOfProductTypes = New Array;
	ArrayOfProductTypes.Add(Enums.ItemsTypes.OwnGoods);
	ArrayOfProductTypes.Add(Enums.ItemsTypes.Work_5);
	
	NewParameter1 = New ChoiceParameter("Filter.ItemsType", New FixedArray(ArrayOfProductTypes));
	NewArray = New Array();
	NewArray.Add(NewParameter1);
	NewParameters = New FixedArray(NewArray);
	
	Items.ProductListValue.ChoiceParameters = NewParameters;
	
	ArrayOfProductTypes.Add(Enums.ItemsTypes.ReusablePackage);
	
	NewParameter1 = New ChoiceParameter("Filter.ItemsType", New FixedArray(ArrayOfProductTypes));
	NewArray = New Array();
	NewArray.Add(NewParameter1);
	NewParameters = New FixedArray(NewArray);
	
	Items.ListOfMaterialsValue.ChoiceParameters = NewParameters;
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure TransferToTheCatalog(Command)
	
	DataArray = New Array;
	If Items.Pages.CurrentPage = Items.LinesOfBusinessPage Then
		DataList = LinesOfBusinessList;
	ElsIf Items.Pages.CurrentPage = Items.PageMaterials Then
		DataList = MaterialList;
	ElsIf Items.Pages.CurrentPage = Items.PageActivityKinds Then
		DataList = ActivityKindList;
	ElsIf Items.Pages.CurrentPage = Items.DepartmentsPage Then
		DataList = DepartmentList;
	ElsIf Items.Pages.CurrentPage = Items.ProductsPage Then
		DataList = ProductList_;
	ElsIf Items.Pages.CurrentPage = Items.PageProductGroups Then
		DataList = ListOfProductGroups;
	EndIf;
	
	For Each Item In DataList Do
		If DataArray.Find(Item.Value) = Undefined
			And ValueIsFilled(Item.Value) Then
			DataArray.Add(Item.Value);
		EndIf;
	EndDo;
	
	Close(DataArray);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion
