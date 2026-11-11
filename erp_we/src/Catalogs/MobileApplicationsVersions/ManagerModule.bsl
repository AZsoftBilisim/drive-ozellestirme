#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Retrieves data about the mobile app version from the layout in XML format.
//
// Parameters:
//  TemplateName - String - name of the layout.
//
// Returns:
//  String - A string containing data about the version of the mobile application from the layout in XML form.
//
Function GetXMLDataForAppVersion(TemplateName) Export
	
	Template = Catalogs.MobileApplicationsVersions.GetTemplate(TemplateName);
	
	Return Template.GetText();

EndFunction

// Generates and returns a list containing the names of layouts from which applications can be loaded.
//
// Returns:
//  ValueList -  contains the names of layouts and their representations.
//
Function DownloadVersions() Export
	
	List = New ValueList();

	TemplatesCollection = Metadata.Catalogs.MobileApplicationsVersions.Templates;

	TextTemplate_ = Metadata.ObjectProperties.TemplateType.TextDocument;
	
	For Each Template In TemplatesCollection Do
		If Template.TemplateType = TextTemplate_ Then
        	TemplateName = Template.Name;
        	List.Add(TemplateName, Template.Synonym);
        EndIf;
    EndDo;

    Return List;

EndFunction

#EndRegion

#EndIf