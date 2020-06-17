//
//  Helpers.swift
//  Rasat
//
//  Created by Göksel Köksal on 16.06.2020.
//  Copyright © 2020 GK. All rights reserved.
//

import Foundation

func sourceLocation(_ file: String, _ line: UInt) -> String {
  let file = URL(string: file)?.deletingPathExtension().lastPathComponent ?? file
  return "\(file):\(line)"
}
