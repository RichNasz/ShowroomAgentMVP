/*
 * ShowroomAgentMVPApp.swift
 * ShowroomAgentMVP
 *
 * Created by Richard Naszcyniec with AI assistance from Claude Code
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import SwiftUI
import SwiftData

@main
struct ShowroomAgentMVPApp: App {
	var sharedModelContainer: ModelContainer = {
		let schema = Schema([
			Project.self,
		])

		// Create a proper store URL in the app's container
		guard let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
			fatalError("Unable to access Application Support directory")
		}

		// Create app-specific subdirectory using display name
		let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? "ShowroomAgentMVP"
		let appDataURL = appSupportURL.appendingPathComponent(appName)
		let storeURL = appDataURL.appendingPathComponent("ShowroomAgent.sqlite")

		// Ensure the app data directory exists
		try? FileManager.default.createDirectory(at: appDataURL, withIntermediateDirectories: true, attributes: nil)

		let modelConfiguration = ModelConfiguration(
			"ShowroomAgent",
			schema: schema,
			url: storeURL
		)

		do {
			return try ModelContainer(for: schema, configurations: [modelConfiguration])
		} catch {
			// More detailed error logging
			print("Failed to create ModelContainer: \(error)")
			print("Store URL: \(storeURL)")
			print("App Support Directory: \(appSupportURL)")
			fatalError("Could not create ModelContainer: \(error)")
		}
	}()
	
	var body: some Scene {
		WindowGroup {
			ContentView()
				.frame(minWidth: 600, minHeight: 400)
		}
		.modelContainer(sharedModelContainer)
	}
}

