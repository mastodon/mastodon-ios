// Copyright © 2026 Mastodon gGmbH. All rights reserved.

import SwiftUI
import MastodonAsset
import MastodonCore
import MastodonLocalization

struct CollectionEditDetailsView: View {
    @Environment(MastodonNavigationRouter.self) private var navigator
    @Environment(CreateCollectionViewModel.self) private var viewModel
    
    var body: some View {
        @Bindable var viewModel = viewModel
        Form {
            
            // NAME
            Section {
                TextField(L10nLookup.Scene.CreateCollection.CollectionDetails.namePlaceholder, text: $viewModel.collectionName)
            } header: {
                Text(L10nLookup.Scene.CreateCollection.CollectionDetails.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .textCase(nil)
                    .accessibilityAddTraits(.isHeader)
            } footer: {
                limitCaption(viewModel.maxCollectionNameLength, isOverLimit: viewModel.nameIsTooLong)
            }
            
            // DESCRIPTION
            Section {
                TextField(L10nLookup.Scene.CreateCollection.CollectionDetails.descriptionPlaceholder, text: $viewModel.collectionDescription, axis: .vertical)
                    .lineLimit(1...4)
            } footer: {
                limitCaption(viewModel.maxCollectionDescriptionLength, isOverLimit: !viewModel.descriptionIsValid)
            }
            
            // TOPIC (hashtag)
            Section {
                TextField(L10nLookup.Scene.CreateCollection.CollectionDetails.topicPlaceholder, text: $viewModel.collectionTopic)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            } footer: {
                Text(L10nLookup.Scene.CreateCollection.CollectionDetails.topicHint)
            }
            
            // LANGUAGE
            Section {
                Button {
                    navigator.push(.createCollectionLanguagePicker(viewModel))
                } label: {
                    NavigationRow(label: L10nLookup.Scene.CreateCollection.CollectionDetails.languagePlaceholder, sublabel: viewModel.languageName ?? L10nLookup.Scene.CreateCollection.CollectionDetails.noLanguageSelected)
                }
            }
            
            // VISIBILITY
            Section(L10nLookup.Scene.CreateCollection.CollectionDetails.Visibility.title) {
                VisibilityRow(
                    title: L10nLookup.Scene.CreateCollection.CollectionDetails.Visibility.publicSetting,
                    subtitle: L10nLookup.Scene.CreateCollection.CollectionDetails.Visibility.publicExplainer,
                    isSelected: viewModel.isDiscoverable
                ) {
                    viewModel.isDiscoverable = true
                }
                
                VisibilityRow(
                    title: L10nLookup.Scene.CreateCollection.CollectionDetails.Visibility.unlistedSetting,
                    subtitle: L10nLookup.Scene.CreateCollection.CollectionDetails.Visibility.unlistedExplainer,
                    isSelected: !viewModel.isDiscoverable
                ) {
                    viewModel.isDiscoverable = false
                }
            }
            
            // SENSITIVE
            Section {
                ToggleRow(label: L10nLookup.Scene.CreateCollection.CollectionDetails.markSensitive, isOn: $viewModel.isSensitive)
            } header: {
                Text(L10nLookup.Scene.CreateCollection.CollectionDetails.contentWarning)
            } footer: {
                Text(L10nLookup.Scene.CreateCollection.CollectionDetails.sensitiveExplainer)
            }
            
            // CREATE BUTTON
            Section {
                createButton
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
        }
        .scrollDismissesKeyboard(.interactively)
        .frame(maxWidth: maxFeedContentWidth)
        .frame(maxWidth: .infinity)
        .background(Color(UIColor.systemGroupedBackground))
        .createCollectionPageTitle(forStep: .details)
        .navigationBarBackButtonHidden(viewModel.isCreating)
    }
    
    @ViewBuilder private var createButton: some View {
        Button {
            viewModel.createCollection(navigator: navigator)
        } label: {
            if viewModel.isCreating {
                ProgressView()
                    .tint(.white)
            } else {
                Text(L10nLookup.Scene.CreateCollection.CollectionDetails.createCollection)
            }
        }
        .buttonStyle(CapsuleButtonStyle(viewModel.detailsValid ? .prominent : .subtle, isLarge: true))
        .disabled(!viewModel.detailsValid || viewModel.isCreating)
        .accessibilityLabel(L10nLookup.Scene.CreateCollection.CollectionDetails.createCollection)
    }
    
    @ViewBuilder private func limitCaption(_ limit: Int, isOverLimit: Bool) -> some View {
        Text(L10nLookup.Scene.CreateCollection.CollectionDetails.characterLimit(limit))
            .foregroundStyle(isOverLimit ? .red : .secondary)
    }
}

private struct VisibilityRow: View {
    let title: String
    let subtitle: String
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: doublePadding) {
                Image(systemName: "checkmark")
                    .foregroundStyle(Asset.Colors.accent.swiftUIColor)
                    .accessibilityHidden(true)
                    .opacity(isSelected ? 1 : 0)
                
                VStack(alignment: .leading, spacing: tinySpacing) {
                    Text(title)
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
